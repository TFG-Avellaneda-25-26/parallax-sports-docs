#!/usr/bin/env node

import { createHash } from "node:crypto"
import { mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises"
import path from "node:path"

const TRANSLATION_API_URL = "https://api-free.deepl.com/v2/translate"
const USAGE_API_URL = "https://api-free.deepl.com/v2/usage"
const CACHE_PATH = path.join(process.cwd(), ".quartz-cache", "translate-es-cache.json")
const CONTENT_DIR = path.join(process.cwd(), "content")
const EN_CONTENT_DIR = path.join(CONTENT_DIR, "en")
const ES_CONTENT_DIR = path.join(CONTENT_DIR, "es")
const DEFAULT_BUDGET = 900000

const args = parseArgs(process.argv.slice(2))
if (args.help) {
  printHelp()
  process.exit(0)
}

const deeplApiKey = process.env.DEEPL_API_KEY
if (!deeplApiKey && !args.dryRun) {
  console.error("Missing DEEPL_API_KEY environment variable.")
  process.exit(1)
}

const sourceRoot = await resolveSourceRoot()
const sourceFiles = await getMarkdownFiles(sourceRoot)
const cache = await loadCache()
const queue = []
let pendingChars = 0

for (const sourceFile of sourceFiles) {
  const relativeFromSource = path.relative(sourceRoot, sourceFile)
  const normalizedRelativeFromSource = toPosix(relativeFromSource)
  const sourceContent = await readFile(sourceFile, "utf8")
  const sourceHash = sha256(sourceContent)

  const outputFile = path.join(ES_CONTENT_DIR, relativeFromSource)
  const outputExists = await fileExists(outputFile)
  const cachedEntry = cache.files[normalizedRelativeFromSource]

  if (!args.all && outputExists && cachedEntry && cachedEntry.sourceHash === sourceHash) {
    continue
  }

  const { frontmatter, body } = splitFrontmatter(sourceContent)
  const { text: protectedBody, tokens } = protectMarkdown(body)

  queue.push({
    sourceFile,
    outputFile,
    relativeFromSource: normalizedRelativeFromSource,
    frontmatter,
    protectedBody,
    tokens,
    sourceHash,
  })

  pendingChars += protectedBody.length
}

if (queue.length === 0) {
  console.log("Everything is up-to-date. No files need translation.")
  process.exit(0)
}

if (args.dryRun) {
  console.log(`Dry run: ${queue.length} files would be translated.`)
  console.log(`Estimated characters to send: ${pendingChars}`)
  queue.slice(0, 20).forEach((item) => {
    console.log(`- ${item.relativeFromSource}`)
  })
  if (queue.length > 20) {
    console.log(`... and ${queue.length - 20} more files`)
  }
  process.exit(0)
}

const usage = await fetchUsage(deeplApiKey)
const effectiveBudget = Number.isFinite(args.budget) ? args.budget : DEFAULT_BUDGET
const currentUsage = usage.character_count
const providerLimit = usage.character_limit
const projectedUsage = currentUsage + pendingChars

if (projectedUsage > effectiveBudget) {
  console.error(
    `Translation blocked by safety budget. Used: ${currentUsage}, pending: ${pendingChars}, budget: ${effectiveBudget}.`,
  )
  process.exit(1)
}

if (providerLimit > 0 && projectedUsage > providerLimit) {
  console.error(
    `Translation blocked by DeepL account limit. Used: ${currentUsage}, pending: ${pendingChars}, provider limit: ${providerLimit}.`,
  )
  process.exit(1)
}

console.log(`Translating ${queue.length} files (${pendingChars} characters estimated)...`)

for (let index = 0; index < queue.length; index += 1) {
  const item = queue[index]
  const translatedProtectedBody = await translateLongText(item.protectedBody, deeplApiKey)
  const translatedBody = restoreTokens(translatedProtectedBody, item.tokens)

  const translatedContent = buildTranslatedDocument({
    sourceFrontmatter: item.frontmatter,
    sourcePath: item.relativeFromSource,
    sourceHash: item.sourceHash,
    translatedBody,
  })

  await mkdir(path.dirname(item.outputFile), { recursive: true })
  await writeFile(item.outputFile, translatedContent, "utf8")

  cache.files[item.relativeFromSource] = {
    sourceHash: item.sourceHash,
    translatedAt: new Date().toISOString(),
    targetPath: toPosix(path.relative(process.cwd(), item.outputFile)),
  }

  console.log(`[${index + 1}/${queue.length}] ${item.relativeFromSource}`)
}

await saveCache(cache)
console.log("Spanish translation update completed.")

function parseArgs(rawArgs) {
  const parsed = {
    all: false,
    dryRun: false,
    help: false,
    budget: Number.NaN,
  }

  for (const arg of rawArgs) {
    if (arg === "--all") {
      parsed.all = true
      continue
    }

    if (arg === "--dry-run") {
      parsed.dryRun = true
      continue
    }

    if (arg === "--help" || arg === "-h") {
      parsed.help = true
      continue
    }

    if (arg.startsWith("--budget=")) {
      const value = Number(arg.split("=")[1])
      if (Number.isFinite(value) && value > 0) {
        parsed.budget = value
      }
      continue
    }
  }

  return parsed
}

function printHelp() {
  console.log("Usage: node scripts/translate-es.mjs [--all] [--dry-run] [--budget=900000]")
  console.log("")
  console.log("Environment variables:")
  console.log("  DEEPL_API_KEY          DeepL API key (required unless --dry-run)")
}

async function resolveSourceRoot() {
  const enExists = await fileExists(EN_CONTENT_DIR)
  return enExists ? EN_CONTENT_DIR : CONTENT_DIR
}

async function getMarkdownFiles(rootDir) {
  const result = []
  await walk(rootDir, result)

  return result.filter((filePath) => {
    if (!filePath.endsWith(".md")) {
      return false
    }

    const relativeToContent = toPosix(path.relative(CONTENT_DIR, filePath))
    if (relativeToContent.startsWith("es/")) {
      return false
    }

    return true
  })
}

async function walk(currentPath, acc) {
  const entries = await readdir(currentPath, { withFileTypes: true })

  for (const entry of entries) {
    const absolutePath = path.join(currentPath, entry.name)

    if (entry.isDirectory()) {
      await walk(absolutePath, acc)
      continue
    }

    acc.push(absolutePath)
  }
}

async function loadCache() {
  if (!(await fileExists(CACHE_PATH))) {
    return { files: {} }
  }

  const raw = await readFile(CACHE_PATH, "utf8")
  try {
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== "object" || !parsed.files) {
      return { files: {} }
    }

    return parsed
  } catch {
    return { files: {} }
  }
}

async function saveCache(cache) {
  await mkdir(path.dirname(CACHE_PATH), { recursive: true })
  await writeFile(CACHE_PATH, `${JSON.stringify(cache, null, 2)}\n`, "utf8")
}

function splitFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?/)
  if (!match) {
    return { frontmatter: "", body: content }
  }

  const fullFrontmatterBlock = match[0]
  const frontmatter = match[1]
  const body = content.slice(fullFrontmatterBlock.length)
  return { frontmatter, body }
}

function protectMarkdown(text) {
  const tokens = []
  let protectedText = text

  const protectPatterns = [
    /```[\s\S]*?```/g,
    /~~~[\s\S]*?~~~/g,
    /<!--([\s\S]*?)-->/g,
    /\[\[[^\]]+\]\]/g,
    /!\[[^\]]*\]\([^\)]+\)/g,
    /\[[^\]]+\]\([^\)]+\)/g,
    /`[^`\n]+`/g,
    /https?:\/\/[^\s\)]+/g,
  ]

  for (const pattern of protectPatterns) {
    protectedText = protectedText.replace(pattern, (match) => {
      const token = `__KEEP_${tokens.length}__`
      tokens.push(match)
      return token
    })
  }

  return { text: protectedText, tokens }
}

function restoreTokens(text, tokens) {
  return text.replace(/__KEEP_(\d+)__/g, (match, idx) => {
    const value = tokens[Number(idx)]
    return typeof value === "string" ? value : match
  })
}

function buildTranslatedDocument({ sourceFrontmatter, sourcePath, sourceHash, translatedBody }) {
  const frontmatter = buildTranslatedFrontmatter(sourceFrontmatter, sourcePath, sourceHash)
  const normalizedBody = translatedBody.startsWith("\n") ? translatedBody.slice(1) : translatedBody
  return `${frontmatter}${normalizedBody}`
}

function buildTranslatedFrontmatter(sourceFrontmatter, sourcePath, sourceHash) {
  const translationKeys = new Set(["lang", "translationMode", "sourcePath", "sourceHash", "translatedAt"])
  const keptLines = sourceFrontmatter
    ? sourceFrontmatter
        .split("\n")
        .filter((line) => {
          const keyMatch = line.match(/^([A-Za-z0-9_-]+):/)
          if (!keyMatch) {
            return true
          }

          return !translationKeys.has(keyMatch[1])
        })
        .filter((line, index, allLines) => {
          if (line.trim() !== "") {
            return true
          }

          if (index === 0 || index === allLines.length - 1) {
            return false
          }

          return true
        })
    : []

  const lines = [
    "---",
    ...keptLines,
    ...(keptLines.length > 0 ? [""] : []),
    "lang: es",
    "translationMode: machine",
    `sourcePath: ${yamlQuote(sourcePath)}`,
    `sourceHash: ${yamlQuote(sourceHash)}`,
    `translatedAt: ${yamlQuote(new Date().toISOString())}`,
    "---",
    "",
  ]

  return `${lines.join("\n")}`
}

async function translateLongText(text, apiKey) {
  const chunks = splitForTranslation(text, 25000)
  const translatedChunks = []

  for (const chunk of chunks) {
    if (chunk.trim() === "") {
      translatedChunks.push(chunk)
      continue
    }

    const translated = await translateChunk(chunk, apiKey)
    translatedChunks.push(translated)
  }

  return translatedChunks.join("")
}

function splitForTranslation(text, maxChunkSize) {
  if (text.length <= maxChunkSize) {
    return [text]
  }

  const parts = text.split(/(\n\s*\n)/)
  const chunks = []
  let current = ""

  for (const part of parts) {
    if (part.length > maxChunkSize) {
      if (current.length > 0) {
        chunks.push(current)
        current = ""
      }

      chunks.push(...splitHard(part, maxChunkSize))
      continue
    }

    if (current.length + part.length > maxChunkSize) {
      if (current.length > 0) {
        chunks.push(current)
      }
      current = part
    } else {
      current += part
    }
  }

  if (current.length > 0) {
    chunks.push(current)
  }

  return chunks
}

function splitHard(text, maxChunkSize) {
  const chunks = []
  for (let i = 0; i < text.length; i += maxChunkSize) {
    chunks.push(text.slice(i, i + maxChunkSize))
  }
  return chunks
}

async function translateChunk(text, apiKey) {
  const params = new URLSearchParams()
  params.set("auth_key", apiKey)
  params.append("text", text)
  params.set("source_lang", "EN")
  params.set("target_lang", "ES")
  params.set("preserve_formatting", "1")

  const response = await fetch(TRANSLATION_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
  })

  if (!response.ok) {
    const errorBody = await response.text()
    throw new Error(`DeepL translation failed (${response.status}): ${errorBody}`)
  }

  const payload = await response.json()
  const translated = payload?.translations?.[0]?.text
  if (typeof translated !== "string") {
    throw new Error("DeepL returned an unexpected translation payload.")
  }

  return translated
}

async function fetchUsage(apiKey) {
  const params = new URLSearchParams()
  params.set("auth_key", apiKey)

  const response = await fetch(`${USAGE_API_URL}?${params.toString()}`)
  if (!response.ok) {
    const errorBody = await response.text()
    throw new Error(`DeepL usage lookup failed (${response.status}): ${errorBody}`)
  }

  const payload = await response.json()
  if (typeof payload?.character_count !== "number" || typeof payload?.character_limit !== "number") {
    throw new Error("DeepL usage response did not include character_count/character_limit.")
  }

  return payload
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex")
}

function yamlQuote(value) {
  return JSON.stringify(value)
}

function toPosix(value) {
  return value.split(path.sep).join("/")
}

async function fileExists(filePath) {
  try {
    await stat(filePath)
    return true
  } catch {
    return false
  }
}

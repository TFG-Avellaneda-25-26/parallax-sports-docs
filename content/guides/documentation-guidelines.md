---
title: Documentation Guidelines
description: "Code documentation standards for Java (Spring) and Kotlin (Ktor) — comment structure, Javadoc quality, and AI guidelines"
tags:
  - guides
aliases:
  - "Code Comments"
  - "Doc Standards"
---

# Documentation Guidelines

Standards for code-level documentation across both the Spring (Java) and Ktor (Kotlin) codebases.

---

## Core principle

Write comments for a developer who has never seen this code before. Every comment should answer at least one of:

- **What** does this do? (not how — that's already in the code)
- **Why** does it work this way?
- **What comes out of it?** (what it returns, what changes, what fails)

If a comment only restates what the code literally says, delete it.

---

## Java (Spring Backend)

### Comment structure

Use three levels of comments in medium or large classes.

**Section banners** — group related methods so the file is scannable:

```java
/*============================================================
  SYNC PIPELINE
  Fetches pages from the external API and upserts into the DB
============================================================*/
```

**Exception handler annotation** — every `@ExceptionHandler` method:

```java
// -> Triggers: malformed JSON / unreadable body || Returns: Bad Request (400)
```

**Javadoc** for public and non-obvious methods:

```java
/**
 * Fetches games for the given league from the external API and saves them to the database.
 * Stops early if the page budget is exhausted or the API rate-limits the request.
 *
 * @param league      the league to sync (NBA or WNBA)
 * @param fromDate    start of the date window to request
 * @param maxPages    maximum number of API pages to consume in one call
 * @return summary of what was fetched and saved, including whether the sync finished or was cut short
 */
```

Only document params that actually change behavior. Skip params that are self-explanatory.

### Writing style

- Write in plain sentences. "Resolves the start date for the sync window" not "Performs resolution of the start date artifact".
- Say what the method does to the world, not how its internals work.
- Include `@return` whenever the return value isn't obvious from the method name.
- Include `@throws` only when callers need to handle a specific failure.
- Document `null` if passing `null` meaningfully changes behavior.

### What to document

- Why a method exists if its name alone doesn't make it clear
- Inputs that change behavior in non-obvious ways
- Side effects (sends an event, writes to a table, evicts a cache)
- Security-relevant constraints
- Anything that surprised you when you first read it

### What not to document

- What the code already says literally
- Java language mechanics
- Implementation details that change often

### Javadoc quality check

1. Does this tell someone new what the method is *for*?
2. Does the `@return` line say what the value *means*, not just its type?
3. Is it still true?

---

## Kotlin (Ktor Microservices)

> The Ktor codebase follows the same core principle but adds infrastructure-specific patterns for the event-driven microservices architecture.

### Scanner line (required for infrastructure functions)

Every function that interacts with infrastructure (Redis, Discord, Gmail, Spring callback) gets a one-line scanner comment:

```kotlin
// -> Source: Redis Stream || Action: Send Gmail Alert || Strategy: Retry on 5xx
```

### Ktor & API contracts

For external API calls:

```kotlin
// -> API: /endpoint || Auth: Type || Scope: Permission
```

### Redis Stream Consumer header

Every class extending `RedisStreamConsumer` must include a topology header:

```kotlin
/**
 * [Worker Name]
 * Stream: [stream.name.v1]
 * Group:  [group-name]
 * Role:   [Brief description]
 */
```

### Section banners

Same pattern as Java:

```kotlin
/*============================================================
  REDIS STREAM CONSUMPTION
  Logic for fetching, processing, and ACK of stream messages
============================================================*/
```

### Style rules

- Use domain vocabulary: Stream, Consumer Group, Artifact, Embed, Idempotency, TTL
- Active voice: "Dispatches each pending alert to the provider" not "This loop iterates..."
- State why a method returns null
- Clarify if a `suspend` function has specific Dispatcher requirements
- Do not explain standard Kotlin features (`apply`, `let`, `map`)

### What not to document (Kotlin)

- Obvious control flow
- Dependency injection (constructor params injected by Koin)
- Logger implementation (`// Logging error` before `logger.error()`)
- Standard library usage

---

## Maintenance rule

If the code behavior changes, update the comments in the same commit. Documentation and code must never diverge.

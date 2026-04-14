---
title: Microservices
description: "Ktor microservices documentation — alert delivery workers for Discord, Email, Telegram, Playwright screenshots, and Cloudinary storage"
tags:
  - microservices
---

# Microservices — Ktor Workers

Five Kotlin microservices built with Ktor 3.4.1 and Koin, plus a shared `common` module. Their job: consume alert messages from Redis Streams, deliver notifications through external providers, and report status back to the Spring backend.

```
┌────────────────── Redis Streams ──────────────────┐
│  alerts.discord.v1  alerts.email.v1  alerts.telegram.v1  │
└───────┬──────────────┬──────────────────┬─────────┘
        ↓              ↓                  ↓
   ms-discord     ms-email          ms-telegram
     (8082)        (8084)             (8083)
        │              │                  │
        └──── screenshot request ─────────┘
                       ↓
                 ms-playwright (8080)
                       ↓
                 ms-cloudinary (8085)
```

## Sections

| Page | What it covers |
|------|---------------|
| [[architecture]] | Multi-module Gradle project, common module, Koin DI, code documentation guidelines |
| [[redis-stream-consumer]] | `RedisStreamConsumer` base class: poll loop, retry, semaphore, callbacks |
| [[ms-discord]] | JDA bot, slash commands (`/events`, `/login`), alert delivery via embeds |
| [[ms-email]] | Gmail OAuth2, Thymeleaf templates, Redis token caching |
| [[ms-telegram]] | Bot polling — what's wired, what's placeholder |
| [[ms-playwright]] | Headless Chromium screenshots, Thymeleaf card rendering |
| [[ms-cloudinary]] | Cloudinary SDK, idempotent uploads, artifact lookup |

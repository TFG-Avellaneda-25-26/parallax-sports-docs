---
title: Microservices Architecture
description: "Multi-module Kotlin project structure — common module, Koin DI, Gradle configuration, and code documentation standards"
tags:
  - microservices
  - architecture
---

# Microservices Architecture

The Ktor microservices live in a single Gradle multi-module repository with a shared `common` module and five service modules.

## Project structure

```
parallax-sports-ktor-microservices/
├── settings.gradle.kts          # Module definitions
├── build.gradle.kts             # Shared dependencies
├── gradle.properties            # Version constants
├── docker-compose.yml           # Redis for local dev
├── common/                      # Shared code
├── ms-discord/                  # Port 8082
├── ms-email/                    # Port 8084
├── ms-telegram/                 # Port 8083
├── ms-playwright/               # Port 8080
└── ms-cloudinary/               # Port 8085
```

## Technology stack

| Component | Version |
|-----------|---------|
| Kotlin | 2.3.0 |
| Ktor | 3.4.1 |
| Koin | 4.1.1 |
| JVM target | 21 |
| Serialization | kotlinx-serialization (JSON) |
| Redis client | Lettuce + Coroutines |
| HTTP engine | CIO (1000 max connections, 100 per route) |
| Logging | SLF4J + Logback |

## Common module

The `common` module provides the foundation that all alert workers share:

### Base class: `RedisStreamConsumer`

The abstract base class for Discord, Email, and Telegram workers. Handles the entire poll-process-callback loop. See [[redis-stream-consumer]] for the deep dive.

### DTOs (shared contracts)

| DTO | Purpose |
|-----|---------|
| `AlertStreamMessage` | Canonical Redis stream payload |
| `EventDTO` | Event contract: id, name, type, status, timestamps, competition, venue |
| `CompetitionDTO` | Competition metadata |
| `VenueDTO` | Venue metadata |
| `AlertStatusCallback` | Worker-to-Spring status report |
| `PlaywrightResponse` | Screenshot service response |
| `CloudinaryCheckResponse` | Artifact lookup result |
| `UploadResponse` | Upload result |
| `NotificationRequest` | Generic notification payload |

### Clients

| Client | Calls | Purpose |
|--------|-------|---------|
| `PlaywrightClient` | `ms-playwright` at `:8080` | Screenshot generation |
| `SpringCallbackService` | Spring at `:8081` | Status and artifact callbacks |

### Koin DI modules

Each concern has its own Koin module for clean composition:

- `networkModule` — shared `HttpClient` (CIO engine, content negotiation)
- `redisModule` — `RedisClient` singleton
- `discordConfigModule`, `telegramConfigModule`, `emailConfigModule` — provider-specific config
- `cloudinaryConfigModule`, `playwrightConfigModule` — service config

### Configuration

All services inherit from `shared-data.conf` (HOCON):

```
parallaxbot {
    redis { url = "redis://localhost:6379", stream = "alerts-stream" }
    api {
        base-url = "http://localhost:8081"
        key = ${API_KEY}
    }
}
```

Each service overlays its own `application.conf` with port and provider-specific settings.

## Service startup pattern

Every microservice follows the same pattern in `Application.kt`:

1. Install Koin DI + ContentNegotiation (JSON)
2. Initialize provider-specific resources (bot, browser, SDK)
3. Inject and launch `RedisStreamConsumer` in `Dispatchers.Default` coroutine
4. Subscribe to `ApplicationStopped` for graceful shutdown

## Build and run

```bash
./gradlew build              # Full build
./gradlew buildFatJar        # Executable JAR per service
./gradlew buildImage         # Docker image (Ktor built-in)
./gradlew runDocker          # Run locally via Docker
```

Local development only requires Redis (provided via `docker-compose.yml` — Redis Stack on ports 6379 and 8001 for RedisInsight).

## Code documentation standard

The Ktor codebase follows specific documentation guidelines for event-driven microservices. See [[documentation-guidelines#kotlin-ktor-microservices]] for the full standard, including scanner line format, stream consumer headers, and section banners.

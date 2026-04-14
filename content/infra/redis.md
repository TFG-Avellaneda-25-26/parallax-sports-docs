---
title: Redis
description: "Redis 7 configuration — Streams for alert transport, caching for OAuth tokens, password auth"
tags:
  - infra
  - redis
---

# Redis

Redis 7 (Alpine) serves two distinct purposes in the platform:

## 1. Alert transport (Redis Streams)

The [[alerts-system|alert system]] uses Redis Streams with consumer groups for asynchronous, multi-channel notification delivery.

| Stream | Consumer Group | Worker |
|--------|---------------|--------|
| `alerts.discord.v1` | `discord-workers` | [[ms-discord]] |
| `alerts.email.v1` | `email-workers` | [[ms-email]] |
| `alerts.telegram.v1` | `telegram-workers` | [[ms-telegram]] |

Each channel also has a DLQ stream (e.g., `alerts.discord.dlq.v1`) for poison messages.

See [[redis-streams-contract]] for the full contract specification.

## 2. Caching

- **OAuth tokens**: The [[ms-email]] microservice caches Gmail access tokens in Redis with a 55-minute TTL, and stores refresh tokens indefinitely
- **Bot permissions**: `BotPermissionCacheService` in the backend caches permission lookups

## Configuration

```yaml
# Spring Boot (backend)
spring.data.redis:
  host: ${REDIS_HOST://localhost}
  port: 6379
  lettuce.pool:
    max-active: 20
    max-idle: 10
    min-idle: 2
    max-wait: 2000ms
```

```yaml
# Docker Compose
redis:
  image: redis:7-alpine
  command: redis-server --requirepass ${REDIS_PASSWORD}
```

## Persistence

Data is persisted to the `redis_data` Docker volume. Default Redis persistence (RDB snapshots) applies.

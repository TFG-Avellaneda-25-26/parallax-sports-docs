---
title: Redis Streams Contract
description: "Producer-consumer contract between Spring and Ktor for alert delivery via Redis Streams"
tags:
  - backend
  - microservices
  - alerts
  - redis
aliases:
  - "Stream Contract"
  - "Alert Stream Protocol"
---

# Redis Streams Contract (Spring → Ktor)

This document defines the producer-consumer contract between the Spring backend and the Ktor alert workers. Both sides must agree on stream names, payload shape, callback endpoints, and processing semantics.

> [!info] Related pages
> - [[alerts-system]] — the backend lifecycle that produces stream messages
> - [[redis-stream-consumer]] — the Ktor base class that consumes them

## Architecture

```
Spring (producer)                    Ktor (consumer)
┌──────────────────┐                ┌──────────────────┐
│ Claim due alerts │                │ XREADGROUP poll   │
│ from PostgreSQL  │──── Redis ────▶│ per channel       │
│                  │    Streams     │                   │
│ Receive status   │◀── HTTP ──────│ Deliver + callback│
│ callbacks        │    POST       │                   │
└──────────────────┘                └──────────────────┘
```

## Channel streams

| Channel | Stream | DLQ |
|---------|--------|-----|
| Telegram | `alerts.telegram.v1` | `alerts.telegram.dlq.v1` |
| Discord | `alerts.discord.v1` | `alerts.discord.dlq.v1` |
| Email | `alerts.email.v1` | `alerts.email.dlq.v1` |

## Consumer groups

| Channel | Group |
|---------|-------|
| Telegram | `alerts.telegram.workers.v1` |
| Discord | `alerts.discord.workers.v1` |
| Email | `alerts.email.workers.v1` |

## Message payload (v1)

| Field | Required | Description |
|-------|----------|-------------|
| `schemaVersion` | yes | Always `v1` |
| `alertId` | yes | Primary key in `user_event_alerts` |
| `userId` | yes | Target user |
| `eventId` | yes | Source event |
| `channel` | yes | `telegram`, `discord`, or `email` |
| `sendAtUtc` | yes | Scheduled delivery time |
| `idempotencyKey` | yes | Deduplication key |
| `attempts` | yes | Current attempt count |
| `maxAttempts` | yes | Maximum retries allowed |
| `artifactRequired` | yes | Whether an image artifact is needed |
| `artifactId` | no | Pre-existing artifact ID (if available) |
| `eventName` | no | Event display name |
| `eventType` | no | Event type category |
| `eventStatus` | no | Current event status |
| `eventStartTimeUtc` | no | Event start time |
| `eventEndTimeUtc` | no | Event end time |
| `competitionName` | no | Parent competition name |
| `venueName` | no | Venue name |
| `venueTimezone` | no | Venue timezone for display |

## Ktor processing rules

1. Consume with `XREADGROUP` from the channel stream
2. Use **at-least-once** semantics
3. `ACK` only after Spring accepts the status callback
4. If callback fails transiently, retry the callback — do not ACK
5. Reclaim pending messages idle longer than `pending-claim-idle-ms` (default: 60000ms)
6. Prefer `XAUTOCLAIM` for pending reclaim
7. Route poison messages to the channel DLQ after consumer-side max retries

## Artifact flow

When `artifactRequired=true` and no `artifactId` is present:

1. Worker calls [[ms-playwright]] to generate a screenshot
2. [[ms-playwright]] checks [[ms-cloudinary]] cache first
3. If cache miss: fetch event data from Spring, render Thymeleaf template, screenshot with Chromium, upload to Cloudinary
4. Worker calls Spring artifact callback with the URL
5. Spring persists the artifact and moves `waiting_artifact` alerts to `scheduled`

See [[artifact-pipeline]] for the full end-to-end flow.

## Callback endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/internal/alerts/{alertId}/status` | POST | Worker status update |
| `/api/internal/alerts/{alertId}/artifact` | POST | Artifact attachment |

**Security:** `X-Api-Key` header with shared secret.

### Status callback body

| Field | Description |
|-------|-------------|
| `status` | `processing`, `sent`, `failed_retryable`, `failed_permanent`, `cancelled` |
| `workerId` | Identifying worker instance |
| `streamMessageId` | Redis stream message ID |
| `providerMessageId` | Provider-specific message ID (e.g., Discord message ID) |
| `errorCode` | Error category code |
| `errorMessage` | Human-readable error |
| `httpStatus` | HTTP status from provider (if applicable) |
| `latencyMs` | Delivery latency |

## Idempotency expectations

- Duplicate callbacks with same status → no-op
- Delivery attempts deduplicated by `(alert_id, stream_message_id, outcome)`
- Alert generation deduplicated by `idempotency_key` in PostgreSQL

## Versioning

- Payload includes `schemaVersion` for non-breaking evolution
- New fields must be additive
- Consumers must ignore unknown fields

## Environment variables checklist

### Spring API (producer + callback receiver)

**Required:**
- `ALERTS_DISPATCH_ENABLED=true`
- `REDIS_HOST=<redis-host>`
- `KTOR_ALERTS_API_KEY=<shared-secret-with-ktor>`

**Optional tuning:**
- `ALERTS_DISPATCH_CRON=0 * * * * *`
- `ALERTS_STREAM_TRIM_ENABLED=true`
- `ALERTS_STREAM_MAX_LEN=200000`

**HTTP fallback** (when Redis publish fails):
- `ALERTS_HTTP_FALLBACK_ENABLED=false`
- `KTOR_ALERTS_BASE_URL=http://<ktor-host>:<ktor-port>`

### Ktor worker (consumer + callback sender)

**Required:**
- `REDIS_HOST=<redis-host>`
- `SPRING_CALLBACK_BASE_URL=http://<spring-host>:<spring-port>`
- `SPRING_CALLBACK_API_KEY=<same-value-as-KTOR_ALERTS_API_KEY>`

Stream/group/DLQ names are hardcoded constants that must match between both sides. See the tables above.

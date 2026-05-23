---
title: RedisStreamConsumer
description: "Abstract base class for all alert workers — poll loop, retry logic, semaphore concurrency, artifact resolution, and status callbacks"
tags:
  - microservices
  - redis
  - alerts
aliases:
  - "Stream Consumer"
  - "Worker Base Class"
---

# RedisStreamConsumer

`RedisStreamConsumer` is the abstract base class that all alert delivery workers extend. It encapsulates the entire consume-process-callback lifecycle so individual providers only need to implement `sendToProvider()`.

> [!info] Contract
> The stream payload and callback format are defined in [[redis-streams-contract]]. This page focuses on the consumer-side mechanics.

## Topology header pattern

Every subclass documents its stream topology:

```kotlin
/**
 * [DiscordAlertConsumer]
 * Stream: alerts.discord.v1
 * Group:  discord-workers
 * Role:   Consume Redis alerts, render embeds, send to Discord
 */
```

## Poll loop

The `start()` method runs an infinite coroutine-based loop:

1. **`XREADGROUP`** with blocking read (5s timeout, batch size 3)
2. For each message, launch processing in a coroutine (bounded by semaphore)
3. On `ApplicationStopped`, break the loop and close resources

## Message processing flow (`onMessageReceived`)

For each stream message:

```
┌─────────────────────────────────────┐
│ 1. Parse AlertStreamMessage         │
│ 2. Check artifactRequired           │
│    ├─ true → getArtifactIfNeeded()  │
│    │         ├─ Call PlaywrightClient│
│    │         └─ Get artifact URL    │
│    └─ false → skip                  │
│ 3. Call sendToProvider() [abstract]  │
│    └─ Returns provider message ID   │
│ 4. reportStatusToSpring()           │
│    └─ POST /api/internal/alerts/... │
│ 5. XACK the stream entry            │
│ 6. XDEL the stream entry            │
└─────────────────────────────────────┘
```

## Concurrency control

A `Semaphore(3)` limits concurrent browser/provider operations. This prevents resource exhaustion, especially for Playwright screenshot generation which is memory-intensive.

## Retry logic

- **Max attempts:** 6 (configurable)
- **Delay between retries:** 15 seconds
- On failure: increment attempts, delay, re-add to stream
- After max attempts exceeded: drop the message with an error log

## Artifact resolution (`getArtifactIfNeeded`)

When `artifactRequired=true`:

1. Call `PlaywrightClient.generateEventScreenshot(eventId)` (see [[ms-playwright]])
2. Playwright checks [[ms-cloudinary]] cache first
3. If cache miss: fetch event data → render template → screenshot → upload → return URL
4. Return the artifact URL for embedding in the notification

## Status callback (`reportStatusToSpring`)

After delivery (or failure), the worker POSTs to Spring:

```
POST /api/internal/alerts/{alertId}/status
X-Api-Key: <shared-secret>

{
  "status": "sent",
  "workerId": "discord-worker-1",
  "providerMessageId": "1234567890",
  "latencyMs": 342
}
```

The ACK only happens after Spring confirms the callback.

## What subclasses implement

Each provider worker overrides one method:

```kotlin
abstract suspend fun sendToProvider(
    message: AlertStreamMessage,
    artifactUrl: String?
): String  // returns provider message ID
```

| Worker | Stream | Implementation |
|--------|--------|----------------|
| [[ms-discord\|DiscordAlertConsumer]] | `alerts.discord.v1` | `DiscordService.sendEventEmbed()` |
| [[ms-email\|EmailAlertConsumer]] | `alerts.email.v1` | `EmailService.sendEvent()` via Gmail API |
| [[ms-telegram\|TelegramAlertConsumer]] | `alerts.telegram.v1` | `TelegramService.sendEvent()` (placeholder) |

## Graceful shutdown

On `ApplicationStopped`:
- Stop the polling loop
- Close Redis connections
- Shut down provider resources (JDA, bot instances)

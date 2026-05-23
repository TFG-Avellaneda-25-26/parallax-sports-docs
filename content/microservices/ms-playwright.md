---
title: Playwright Microservice
description: "Headless Chromium screenshot generation for event card artifacts"
tags:
  - microservices
  - alerts
aliases:
  - "Screenshot Service"
---

# ms-playwright

The Playwright microservice generates screenshot images of event cards. These images are attached to alert notifications as visual artifacts.

**Port:** 8080

> [!info] No Redis consumer
> Unlike the delivery workers, ms-playwright does not consume Redis Streams. It's called via HTTP by the alert workers when `artifactRequired=true`.

## Request flow

```
POST /api/internal/screenshot { eventId }
  │
  ├─ 1. Check Cloudinary cache (GET ms-cloudinary/check/{eventId})
  │     ├─ cached → return URL immediately
  │     └─ not cached ↓
  │
  ├─ 2. Fetch event data from Spring (GET /api/internal/events/{eventId})
  │
  ├─ 3. Render Thymeleaf event-card template + CSS
  │
  ├─ 4. Screenshot with Playwright (Chromium headless, 800×450 JPEG)
  │
  ├─ 5. Upload to ms-cloudinary (POST /upload multipart)
  │
  └─ 6. Return URL
```

## Components

- **`PlaywrightService`** — renders HTML via Thymeleaf in headless Chromium, captures JPEG screenshot, closes browser context after each render
- **`ConfigurePlaywright`** — initializes Playwright singleton and launches Chromium browser (headless mode)

## Response contract

```json
{
  "success": true,
  "url": "https://res.cloudinary.com/.../parallaxbot/events/12345.jpg",
  "errorMessage": null
}
```

## Concurrency

The [[redis-stream-consumer|RedisStreamConsumer]] base class limits concurrent Playwright calls to 3 via a semaphore. This prevents memory exhaustion from running too many headless browser instances simultaneously.

See [[artifact-pipeline]] for the full end-to-end artifact flow.

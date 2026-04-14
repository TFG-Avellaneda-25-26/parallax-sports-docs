---
title: Artifact Pipeline
description: "Alert needs an image → Playwright screenshot → Cloudinary upload → artifact attached to alert"
tags:
  - alerts
  - microservices
---

# Artifact Pipeline

When an alert requires a visual artifact (e.g., an event card image for Discord embeds), this pipeline generates and caches the screenshot.

## Sequence

```mermaid
sequenceDiagram
    participant Worker as Ktor Worker
    participant PW as ms-playwright
    participant CL as ms-cloudinary
    participant Spring
    participant DB as PostgreSQL

    Worker->>PW: POST /api/internal/screenshot {eventId}
    PW->>CL: GET /check/{eventId}
    
    alt Cached
        CL-->>PW: {exists: true, url: "..."}
        PW-->>Worker: {success: true, url: "..."}
    else Not cached
        CL-->>PW: {exists: false}
        PW->>Spring: GET /api/internal/events/{eventId}
        Spring-->>PW: Event data (name, competition, venue, time)
        PW->>PW: Render Thymeleaf template + CSS
        PW->>PW: Screenshot with Chromium (800×450 JPEG)
        PW->>CL: POST /upload (multipart)
        CL-->>PW: {success: true, url: "..."}
        PW-->>Worker: {success: true, url: "..."}
    end

    Worker->>Spring: POST /api/internal/alerts/{id}/artifact {url}
    Spring->>DB: Persist alert_artifact, link to alert
    Note over Spring: Move waiting_artifact → scheduled
```

## Components involved

| Service | Role |
|---------|------|
| [[redis-stream-consumer\|Ktor worker]] | Initiates artifact request when `artifactRequired=true` |
| [[ms-playwright]] | Orchestrates screenshot generation |
| [[ms-cloudinary]] | Cache check + persistent storage |
| Spring API | Provides event data + receives artifact callback |

## Concurrency control

A semaphore in the [[redis-stream-consumer|RedisStreamConsumer]] base class limits concurrent Playwright calls to 3. Headless Chromium instances are memory-intensive.

## Caching

Cloudinary acts as the cache layer. Once an event card is generated, subsequent requests for the same event return the cached URL immediately — no browser rendering needed. Uploads are idempotent (`overwrite=true`).

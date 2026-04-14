---
title: Cloudinary Microservice
description: "Image storage and lookup via Cloudinary SDK — idempotent uploads and artifact caching"
tags:
  - microservices
---

# ms-cloudinary

The Cloudinary microservice wraps the Cloudinary SDK to provide image storage and lookup for alert artifacts.

**Port:** 8085

## Endpoints

### Check for existing artifact

```
GET /check/{eventId}
→ { "exists": true, "url": "https://...", "eventId": "12345" }
```

Queries the Cloudinary Admin API for `parallaxbot/events/{eventId}`.

### Upload new artifact

```
POST /upload (multipart: file bytes + eventId)
→ { "success": true, "url": "https://...", "eventId": "12345" }
```

Uploads to Cloudinary folder `parallaxbot/events/{eventId}` with `overwrite=true` for idempotent uploads.

## Design

- **Idempotent** — `overwrite=true` means the same event ID always produces the same artifact URL. Safe for replay.
- **Cache-first** — [[ms-playwright]] checks here before generating a new screenshot, avoiding redundant browser renders.
- **IO dispatcher** — upload and lookup operations run on `Dispatchers.IO`.

## Configuration

```hocon
parallaxbot.cloudinary {
    cloudName = ${CLOUDINARY_CLOUD_NAME}
    apiKey = ${CLOUDINARY_API_KEY}
    apiSecret = ${CLOUDINARY_API_SECRET}
}
```

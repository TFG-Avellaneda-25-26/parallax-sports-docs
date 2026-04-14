---
title: Email Microservice
description: "Gmail OAuth2 integration with Thymeleaf templates for alert email delivery"
tags:
  - microservices
  - alerts
  - auth
---

# ms-email

The email microservice delivers alert notifications and verification emails via the Gmail API using OAuth2 authentication.

**Port:** 8084
**Stream:** `alerts.email.v1`
**Group:** `email-workers`

## OAuth2 token management

`GoogleTokenManager` handles the full OAuth2 lifecycle:

1. **Initial exchange** — user visits `/auth/google/login` → redirects to Google consent → callback at `/auth/callback?code=...` → exchanges code for access + refresh tokens
2. **Token storage** — refresh token stored in Redis (no TTL), access token cached for 55 minutes
3. **Automatic refresh** — `getAccessToken()` returns cached token or transparently refreshes when expired

> [!tip] Why Redis for tokens?
> The refresh token persists across service restarts without needing a database. The 55-minute access token TTL avoids unnecessary OAuth exchanges (Google tokens expire at 60 minutes).

## Alert delivery

`EmailAlertConsumer` extends [[redis-stream-consumer|RedisStreamConsumer]]:

1. Fetches a valid access token via `GoogleTokenManager`
2. Calls `EmailService.sendEvent(message, artifactUrl)`
3. Returns the Google message ID

## Email rendering

`EmailService` uses Thymeleaf to render HTML email templates:

- **Event alert template** — event details with optional image, competition context
- **Verification email template** — verification link for new user accounts

Emails are sent via the Gmail API v1 (`/users/me/messages/send`) as Base64-encoded raw MIME messages.

## HTTP endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/auth/google/login` | GET | Redirect to Google OAuth consent |
| `/auth/callback` | GET | Token exchange callback |
| `/internal/email/verify` | POST | Send verification email |

## Configuration

```hocon
parallaxbot.email {
    client { id = ${CLIENT_ID}, secret = ${CLIENT_SECRET} }
    username = ${EMAIL}
    from = "ParallaxSports"
}
```

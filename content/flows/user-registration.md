---
title: User Registration Flow
description: "Register → email verification → login → JWT → dashboard"
tags:
  - auth
  - architecture
---

# User Registration Flow

Traces the path from a new user signing up to accessing the dashboard.

## Sequence

```mermaid
sequenceDiagram
    participant User
    participant Angular
    participant Spring
    participant DB as PostgreSQL
    participant Email as ms-email

    User->>Angular: Fill register form
    Angular->>Spring: POST /api/auth/register
    Spring->>DB: Create user (email_verified=false)
    Spring->>Email: Send verification email
    Email->>User: Verification link in inbox

    User->>Spring: Click verification link (GET /api/auth/verify?token=...)
    Spring->>DB: Set email_verified=true

    User->>Angular: Fill login form
    Angular->>Spring: POST /api/auth/login
    Spring->>Angular: {accessToken, refreshToken}
    Angular->>Angular: Store token, redirect to dashboard

    Note over Angular: Subsequent requests
    Angular->>Spring: GET /api/... (Authorization: Bearer)
    
    Note over Angular: Token refresh
    Angular->>Spring: POST /api/auth/refresh
    Spring->>Angular: {newAccessToken, newRefreshToken}
```

## Key details

- **Registration** creates a user with `email_verified=false`. The `@RequiresVerifiedEmail` AOP annotation blocks certain operations until verification completes.
- **Verification email** is sent via the [[ms-email]] microservice using Gmail OAuth2 and Thymeleaf templates.
- **Unverified cleanup**: `UnverifiedUserCleanupScheduler` removes accounts that never complete verification.
- **JWT tokens**: 15-minute access token + 7-day refresh token. See [[authentication]].
- **OAuth2 alternative**: Users can also register/login via Discord or Google OAuth2, which provisions a user automatically via `OAuthUserProvisioningService`.

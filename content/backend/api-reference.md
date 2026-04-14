---
title: API Reference
description: "REST API surface — endpoints overview, Swagger/OpenAPI, and Postman collections"
tags:
  - backend
  - api
aliases:
  - "REST API"
  - "Swagger"
---

# API Reference

The backend exposes a REST API documented via OpenAPI 3 (Swagger). Interactive API docs are available at `/swagger-ui.html` when the backend is running.

## OpenAPI configuration

- **Title:** Parallax Sports API
- **Description:** Multi-sport event tracking, follow management, and notification delivery
- **Security:** HTTP Bearer with JWT format (global requirement)

## Endpoint groups

### Authentication (`/api/auth/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/register` | POST | Public | Create account |
| `/login` | POST | Public | Email/password login → JWT tokens |
| `/refresh` | POST | Public | Refresh token rotation |
| `/logout` | POST | Public | Revoke refresh token |
| `/verify` | GET | Public | Email verification callback |
| `/resend-verification` | POST | Authenticated | Resend verification email |
| `/unlink-identity` | DELETE | Authenticated | Remove OAuth provider link |

### Users (`/api/users/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/` | GET | Authenticated | List users (paginated) |
| `/{id}` | GET | Authenticated | Get user by ID |
| `/{id}` | PUT | Authenticated | Update user |

### User Settings (`/api/user-settings/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/` | GET | Authenticated | Get current user settings |
| `/` | PUT | Authenticated | Update settings |

### Formula 1 (`/api/formula1/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/sessions/{year}` | GET | Public | Get all sessions for a year |

### Basketball (`/api/basketball/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/games` | GET | Public | Query games by date range |
| `/teams` | GET | Public | Get teams by league |

### Bot (`/api/bot/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/check-permission` | GET | API Key | Check user bot command permission |

### Internal — Alert Callbacks (`/api/internal/alerts/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/{alertId}/status` | POST | API Key | Worker status callback |
| `/{alertId}/artifact` | POST | API Key | Artifact attachment callback |

### Admin (`/api/admin/`)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/formula1/sync/{year}` | POST | ADMIN | Trigger F1 year sync |
| `/basketball/sync` | POST | ADMIN | Trigger basketball sync |
| `/sync/daily` | POST | ADMIN | Trigger all daily sync jobs |

## Postman collections

Pre-built Postman collections are available at `postman/collections/Parallax Sports API/`:

- **Auth** — Register, Login, Refresh, Verify Email, Resend Verification
- **Users** — Get All, Get by ID, Update
- **User Settings** — Get, Update
- **Formula 1** — Get Sessions by Year
- **Basketball** — Get Games, Get Teams
- **Admin - Formula 1** — Sync Year
- **Admin - Basketball** — Sync Basketball
- **Admin - Sync** — Trigger Daily Sync
- **Internal Alerts** — Status Callback, Artifact Callback

Local environment configuration: `postman/environments/Parallax Sports - Local.yaml`

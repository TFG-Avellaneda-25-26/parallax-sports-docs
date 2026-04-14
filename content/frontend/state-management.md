---
title: State Management
description: "Angular Signals for reactive state — auth store, theme persistence, and error state"
tags:
  - frontend
---

# State Management

The frontend uses Angular Signals for reactive state management — no NgRx, no external state library. Each concern has its own signal-based store.

## Stores

### Auth store (`features/auth/model/`)

Manages authentication state:
- Access token
- Current user info
- Authentication status

Token persistence uses the auth interceptor in `features/auth/lib/`, which automatically attaches the Bearer header and handles refresh on expiry.

### Theme store (`features/theme-switch/model/theme.store.ts`)

Signal-based dark/light theme switching with localStorage persistence. The toggle component in `features/theme-switch/ui/theme-toggle.ts` reads and updates this store.

### Error state (`shared/model/error-state.store.ts`)

Global error state signal that captures API errors. The error interceptor in `shared/api/error-interceptor.ts` feeds errors into this store, and the error page reads from it.

### Sport event store (`entities/sport-event/model/`)

Signal store for sport events:
- `events` — list of sport events
- `loading` — loading state
- `error` — error state

## HTTP layer

- **`ApiClient`** (`shared/api/api-client.ts`) — wrapper around `HttpClient` with typed `get`/`post`/`put`/`delete` methods
- **`API_BASE_URL`** — `InjectionToken` configured in `shared/config/api.config.ts` (default: `https://localhost:8080`)
- **`withFetch()`** — uses modern Fetch API instead of XMLHttpRequest
- **Error interceptor** — centralized error handling that routes API errors to the global error store

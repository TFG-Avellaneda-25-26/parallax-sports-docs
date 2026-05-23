---
title: Feature-Sliced Design
description: "FSD architectural methodology applied to the Angular 21 frontend — layers, slices, segments, and import rules"
tags:
  - frontend
  - architecture
aliases:
  - "FSD"
  - "Feature-Sliced Design"
---

# Feature-Sliced Design

Feature-Sliced Design (FSD) is a frontend architectural methodology that organizes code into a strict three-level hierarchy: **Layers → Slices → Segments**. Its core guarantee: a module can only import from layers strictly below its own. This prevents circular dependencies and keeps changes isolated.

This project is an **Angular 21** app using standalone components, Signals, and no NgModules. FSD is applied from the start. Official reference: [Feature-Sliced Design Overview](https://feature-sliced.design/docs/get-started/overview)

---

## The Three Levels

### Layers (top → bottom, import direction: downward only)

| Layer | Purpose | Has Slices? |
|---|---|---|
| `app` | App bootstrap: router, global providers, styles, entrypoint | No — segments only |
| `pages` | Full route-level screens | Yes |
| `widgets` | Large reusable self-contained UI blocks | Yes |
| `features` | User-facing interactions with business value (reused across pages) | Yes |
| `entities` | Business domain models the app works with | Yes |
| `shared` | Infrastructure: HTTP client, UI kit, utils — no business logic | No — segments only |

> `processes` layer is deprecated. Do not use it.

**Import rule (critical):** A file inside `features/auth` can import from `entities/*` and `shared/*`, but NOT from `pages/*`, `widgets/*`, or another `features/*` slice.

`app` and `shared` are exceptions: they have no slices, so their segments can freely import each other within the same layer.

### Slices

Slices partition a layer by business domain. Names are free-form and project-specific. Sibling slices (same layer) must NOT import each other — coordination belongs in the layer above. Each slice exposes a public API via `index.ts`; external code must only reference that file, never internal paths.

**Cross-entity imports** use the `@x` notation:
```ts
// entities/artist/model/artist.ts
import type { Song } from "entities/song/@x/artist";
```

### Segments

Standard segment names (used inside slices, and directly inside `app`/`shared`):

| Segment | Contains |
|---|---|
| `ui` | Components, formatters, styles |
| `api` | HTTP request functions, data types, mappers |
| `model` | Schemas, interfaces, Signal stores, business logic |
| `lib` | Internal library code needed by this slice |
| `config` | Configuration files, feature flags |

Custom segments are allowed, especially in `app` and `shared`. Name by **purpose** (what the code does), not by essence — avoid `components/`, `hooks/`, `types/` as segment names.

---

## Import Rules Table

| Layer | Can import from |
|---|---|
| `app` | `pages`, `widgets`, `features`, `entities`, `shared` |
| `pages/*` | `widgets`, `features`, `entities`, `shared` |
| `widgets/*` | `features`, `entities`, `shared` |
| `features/*` | `entities`, `shared` |
| `entities/*` | `shared` (+ `@x` cross-imports between entities only when necessary) |
| `shared` | External dependencies only |

---

## Path Aliases (tsconfig)

```jsonc
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@app/*":      ["src/app/*"],
      "@pages/*":    ["src/pages/*"],
      "@widgets/*":  ["src/widgets/*"],
      "@features/*": ["src/features/*"],
      "@entities/*": ["src/entities/*"],
      "@shared/*":   ["src/shared/*"]
    }
  }
}
```

---

## Project Layer Structure

### `app` — Global composition (no slices)

- `app.ts`, `app.html`, `app.css` — root component shell
- `app.config.ts` — global providers
- `app.routes.ts` — lazy-loaded route definitions + guards

**Lazy routes:**
```ts
{ path: '',          loadComponent: () => import('@pages/landing') },
{ path: 'login',     loadComponent: () => import('@pages/login') },
{ path: 'register',  loadComponent: () => import('@pages/register') },
{ path: 'dashboard', loadComponent: () => import('@pages/dashboard'), canActivate: [authGuard] },
{ path: 'settings',  loadComponent: () => import('@pages/settings'), canActivate: [authGuard] },
{ path: 'about',     loadComponent: () => import('@pages/about') },
{ path: 'error',     loadComponent: () => import('@pages/error') },
{ path: '**',        redirectTo: 'error' },
```

### `pages` — Route screens

Slices: `landing`, `login`, `register`, `dashboard`, `error`, `settings`, `about`.

Each slice pattern:
```
pages/<name>/
  ui/<name>-page.ts
  ui/<name>-page.html
  ui/<name>-page.css
  index.ts
```

### `widgets` — Reusable composite UI blocks

- `header` — `ui/` only
- `event-feed` — `ui/` + `model/` (view-mode state)

### `features` — User interactions with business value

| Slice | Segments | Responsibility |
|---|---|---|
| `auth` | `ui`, `api`, `model`, `lib` | Login/register forms; auth API calls; Signal store + guard; interceptor + token persistence |
| `theme-switch` | `ui`, `model` | Dark/light theme toggle + local persistence |
| `view-mode-toggle` | `ui`, `api`, `model` | Cards/table mode, synced to backend |
| `email-verification` | `ui` | Unverified account notice |

### `entities` — Business domain models

| Slice | Segments | Contents |
|---|---|---|
| `user` | `model`, `ui` | Types (`UserResponse`, `UserRole`); avatar component |
| `sport-event` | `api`, `model`, `ui` | Events HTTP service; Signal store; card and table row components |

### `shared` — Cross-cutting infrastructure (no slices)

| Segment | Contents |
|---|---|
| `api` | Base HTTP client |
| `model` | Common types (`ProblemDetails`) |
| `ui` | Atomic components (`button`, `spinner`) |
| `lib` | Validators |
| `config` | API tokens, global configuration |

---

## Artifact Placement Quick Reference

| Angular artifact | Correct location |
|---|---|
| Page component | `pages/<slice>/ui/` |
| Feature UI (forms, toggles) | `features/<slice>/ui/` |
| Entity UI (cards, rows) | `entities/<slice>/ui/` |
| Shared atomic UI | `shared/ui/<component>/` |
| Widget | `widgets/<slice>/ui/` |
| Business API service | `features/<slice>/api/` or `entities/<slice>/api/` |
| Base HTTP client | `shared/api/` |
| Auth interceptor | `features/auth/lib/` |
| Auth guard | `features/auth/model/` |
| Types / interfaces | `<layer>/<slice>/model/*.types.ts` |
| Signal store | `<layer>/<slice>/model/*.store.ts` |
| Validator | `shared/lib/` |
| Route resolver | `pages/<slice>/model/` |

---

## Authentication Architecture (FSD Pattern)

1. **Get credentials** — `features/auth/ui/` (login + register forms)
2. **Send credentials** — `features/auth/api/` holds `login()`, `register()`, `refresh()`
3. **Store token** — `features/auth/lib/` (interceptor + token persistence), injected via `app.config.ts`
4. **Guard protected routes** — `features/auth/model/authGuard` gates `dashboard` and `settings`

**Automatic token refresh** is middleware in the auth interceptor:
- Request fails with expiry status + refresh token exists → call `refresh()` → retry
- Refresh failure → clear token store → redirect to login

---

## Key Rules Summary

1. **Import direction is strictly downward.** Never import from the same layer (except within `app` and `shared`).
2. **Sibling slices are isolated.** `features/auth` cannot import `features/theme-switch`.
3. **Every slice has a public API** (`index.ts`). External code imports only from that file.
4. **`app` and `shared` have no slices** — only segments.
5. **Features are for reused interactions.** If something is used on only one page, keep it in that page's slice.
6. **Segment names describe purpose, not essence.** Use `api`, `model`, `ui`, `lib`, `config` — not `services`, `components`, `types`.
7. **Cross-entity data relationships** use `@x` notation to make the coupling explicit.

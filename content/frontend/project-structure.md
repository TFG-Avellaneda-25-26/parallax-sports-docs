---
title: Frontend Structure
description: "How Feature-Sliced Design maps to the Angular project's actual directory tree"
tags:
  - frontend
  - architecture
---

# Project Structure

The Angular project follows [[fsd-architecture|Feature-Sliced Design]] from the start. Here's how the methodology maps to the actual `src/` tree.

```
src/
├── app/                    # App layer (global composition)
│   ├── app.ts              # Root component (RouterOutlet + ThemeToggle)
│   ├── app.html
│   ├── app.css
│   ├── app.config.ts       # Global providers (router, HTTP, interceptors)
│   └── app.routes.ts       # Lazy-loaded route definitions
│
├── pages/                  # Pages layer (route screens)
│   ├── landing/
│   ├── login/
│   ├── register/
│   ├── dashboard/
│   ├── settings/
│   ├── about/
│   └── error/
│       ├── error-page.ts
│       └── ui/error-display/
│
├── entities/               # Entities layer (domain models)
│   ├── error/
│   │   └── model/problem-details.type.ts    # RFC 7807
│   ├── user/
│   │   ├── model/
│   │   └── ui/
│   └── sport-event/
│       ├── api/
│       ├── model/
│       └── ui/
│
├── features/               # Features layer (reusable interactions)
│   ├── auth/
│   │   ├── api/            # login(), register(), refresh()
│   │   ├── model/          # Signal store + auth guard
│   │   ├── ui/             # Login/register forms
│   │   └── lib/            # Auth interceptor + token persistence
│   ├── email-verification/
│   │   └── ui/
│   ├── theme-switch/
│   │   ├── model/theme.store.ts
│   │   └── ui/theme-toggle.ts
│   └── view-mode-toggle/
│       ├── api/
│       ├── model/
│       └── ui/
│
├── shared/                 # Shared layer (infrastructure)
│   ├── api/
│   │   ├── api-client.ts   # HttpClient wrapper
│   │   └── error-interceptor.ts
│   ├── config/
│   │   └── api.config.ts   # API_BASE_URL token
│   ├── lib/
│   │   └── gsap.ts         # GSAP animation helpers
│   ├── model/
│   │   └── error-state.store.ts
│   └── ui/
│       ├── button/
│       └── spinner/
│
├── main.ts                 # Bootstrap entry point
├── index.html
└── styles.css              # Global styles
```

## Path aliases

```jsonc
// tsconfig.app.json
"@app/*"      → "src/app/*"
"@pages/*"    → "src/pages/*"
"@widgets/*"  → "src/widgets/*"
"@features/*" → "src/features/*"
"@entities/*" → "src/entities/*"
"@shared/*"   → "src/shared/*"
```

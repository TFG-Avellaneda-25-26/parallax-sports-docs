---
title: Pages & Routing
description: "Lazy-loaded Angular routes, auth guards, and error fallback"
tags:
  - frontend
---

# Pages & Routing

All routes use lazy loading via dynamic `loadComponent` imports. Protected pages are gated by the auth guard from `features/auth/model`.

## Route table

```ts
{ path: '',          loadComponent: () => import('@pages/landing')   }
{ path: 'login',     loadComponent: () => import('@pages/login')     }
{ path: 'register',  loadComponent: () => import('@pages/register')  }
{ path: 'dashboard', loadComponent: () => import('@pages/dashboard'), canActivate: [authGuard] }
{ path: 'settings',  loadComponent: () => import('@pages/settings'),  canActivate: [authGuard] }
{ path: 'about',     loadComponent: () => import('@pages/about')     }
{ path: 'error',     loadComponent: () => import('@pages/error')     }
{ path: '**',        redirectTo: 'error'                             }
```

## Page descriptions

| Page | Status | Description |
|------|--------|-------------|
| Landing | Built | Public homepage with parallax animations (see [[animations]]) |
| Login | In progress | Login form, calls `features/auth/api` |
| Register | In progress | Registration form with email |
| Dashboard | Stubbed | Main authenticated view — sport events feed |
| Settings | Stubbed | User preferences (theme, view mode, notifications) |
| About | Stubbed | Project information |
| Error | Built | Error display with `ErrorDisplayComponent` |

## Auth guard

`authGuard` in `features/auth/model/` checks for a valid access token. Unauthenticated users are redirected to login.

---
title: Rutas y páginas
description: Árbol de rutas Angular de Parallax Sports, guards, resolver y descripción de cada página.
tags:
  - frontend
  - routing
  - guards
---

# Rutas y páginas

## Árbol de rutas

Definido en `src/app/app.routes.ts`. Todos los componentes se cargan con **lazy loading** mediante dynamic imports.

```
/ (pathMatch: full)
  canActivate: [redirectIfAuthenticatedGuard]
  → LandingPage

/auth
  canActivate: [redirectIfAuthenticatedGuard]
  → AuthPage

(canActivateChild: [authGuard])
  /dashboard
    resolve: { events: eventResolver }
    → DashboardPage

  /settings
    canActivate: [verifiedEmailGuard]
    → SettingsPage
      /settings/account     → AccountComponent
      /settings/preferences → PreferencesComponent
      /settings/follows     → FollowsComponent
      /settings/admin       → AdminComponent

/error
  → ErrorPage

**
  → redirect to /
```

## Guards

### `authGuard` (CanActivateChild)

- Llama a `UserStore.loadUser()` (GET `/api/users/me`).
- Si la cookie de sesión es válida, el usuario se carga y la navegación continúa.
- Si la respuesta es 401 (no autenticado): redirige a `/`.
- Si se lanza cualquier excepción inesperada: redirige a `/error`.

Protege `/dashboard` y `/settings` como `canActivateChild` del grupo raíz.

### `redirectIfAuthenticatedGuard` (CanActivate)

- Si `UserStore.isAuthenticated()` es `true`: redirige a `/dashboard`.
- Si no: permite la navegación (hacia `/` o `/auth`).

Evita que un usuario ya autenticado vuelva a la landing o al formulario de login.

### `verifiedEmailGuard` (CanActivate)

- Requiere que `UserStore.isVerified()` sea `true`.
- Si el email no está verificado: bloquea el acceso a `/settings`.
- Se ejecuta después de `authGuard` (que ya ha cargado el usuario).

## Resolver

### `eventResolver` (ResolveFn)

- Se ejecuta **antes** de que `DashboardPage` renderice.
- Llama a `EventStore.loadInitialEvents()` (ventana de 3 meses desde hoy).
- Evita el parpadeo de pantalla vacía al entrar al dashboard por primera vez.

## Páginas

| Página          | Ruta         | Descripción                                                                                                                                   |
| --------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `LandingPage`   | `/`          | Héroe con GSAP MorphSVG que cicla entre 7 logos deportivos (Basketball, Dota2, Valorant, F1, StarCraft, CS, LoL) + parallax con ScrollTrigger |
| `AuthPage`      | `/auth`      | Provee `AuthStore` a nivel de componente; renderiza `AuthFormComponent` con modos login/register                                              |
| `DashboardPage` | `/dashboard` | ChangeDetection OnPush; sentinel ScrollTrigger para infinite scroll; alterna vista cards/table mediante `DashboardViewStore`                  |
| `SettingsPage`  | `/settings`  | Provee `SettingsNavStore`; sidebar `SettingsNavComponent` + `RouterOutlet` para sub-rutas                                                     |
| `ErrorPage`     | `/error`     | Renderiza `ErrorDisplayComponent` con el `ProblemDetails` almacenado en `ErrorStore`                                                          |

## Fuentes

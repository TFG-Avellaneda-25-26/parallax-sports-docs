---
title: Arquitectura Feature-Sliced Design
description: "Metodología Feature-Sliced Design aplicada a Angular 21 en Parallax Sports: capas, regla de importación, Sheriff y path aliases."
tags:
  - frontend
  - arquitectura
  - fsd
---

# Arquitectura Feature-Sliced Design

## Fuentes

- [Feature-Sliced Design: Getting Started](https://feature-sliced.design/docs/get-started/overview)

---

Parallax Sports aplica [Feature-Sliced Design (FSD)](https://feature-sliced.design/) sobre Angular 21 con standalone components y sin NgModules.

## Las 6 capas

Las capas se ordenan de mayor a menor nivel de abstracción. **Una capa solo puede importar de capas inferiores** a la suya.

### 1. `app/`

Configuración global de la aplicación:

- Bootstrap y punto de entrada (`app.ts`)
- `app.config.ts`: `provideZonelessChangeDetection`, `provideRouter`, `provideHttpClient` + interceptores
- `app.routes.ts`: árbol de rutas raíz con lazy loading
- Providers e interceptores globales

### 2. `pages/`

Componentes de página completa, uno por ruta:

| Página       | Ruta         |
| ------------ | ------------ |
| `landing/`   | `/`          |
| `auth/`      | `/auth`      |
| `dashboard/` | `/dashboard` |
| `settings/`  | `/settings`  |
| `error/`     | `/error`     |

Cada página puede proveer stores de alcance local y componer widgets y features.

### 3. `widgets/`

Bloques de UI compuestos reutilizables que no encajan en una sola feature:

- `header/`: cabecera global de la aplicación
- `settings-nav/`: navegación lateral de ajustes

Los widgets pueden usar features y entities, pero no pueden depender de pages.

### 4. `features/`

Funcionalidades orientadas al usuario, agrupadas por dominio:

| Slice           | Contenido                                                                    |
| --------------- | ---------------------------------------------------------------------------- |
| `auth/`         | AuthFormComponent, OtpDialogComponent, VerifyEmailDialogComponent, AuthStore |
| `dashboard/`    | DashboardToolbar, FilterDrawer, FilterTree, stores de filtro y vista         |
| `event/`        | EventCardComponent, EventCardGridComponent, EventTableComponent, EventStore  |
| `settings/`     | Sub-secciones Account, Preferences, Follows, Admin                           |
| `theme-switch/` | ThemeToggleComponent (View Transitions API + MorphSVG)                       |

Las features solo pueden importar de entities y shared.

### 5. `entities/`

Acceso a datos del dominio, modelos y servicios HTTP:

| Slice         | Contenido                                                              |
| ------------- | ---------------------------------------------------------------------- |
| `auth/`       | AuthModel, auth.schema.ts, AuthService                                 |
| `event/`      | event.model.ts, EventService                                           |
| `user/`       | user.model.ts, UserStore, guards (auth, redirectIfAuth, verifiedEmail) |
| `admin-user/` | model + service                                                        |
| `audit/`      | model + service                                                        |
| `loadtest/`   | model + service                                                        |
| `timezone/`   | timezone-options.model.ts                                              |

Las entities solo pueden importar de shared.

### 6. `shared/`

Utilidades y primitivas sin dependencias de negocio:

- `api/`: ApiClient wrapper
- `interceptors/`: authInterceptor, errorInterceptor
- `stores/`: ThemeStore, ErrorStore, SettingsNavStore
- `lib/`: GSAP, pipes, helpers
- `models/`: ProblemDetails, settings-nav.model.ts
- `ui/`: componentes UI genéricos y estilos globales

La capa `shared` no puede importar de ninguna otra capa.

## Regla de importación

```
app → pages → widgets → features → entities → shared
```

Importaciones laterales (entre slices del mismo nivel) y hacia arriba están **prohibidas**.

## Sheriff enforcement

El cumplimiento de la regla de importación se automatiza con [Sheriff](https://github.com/softarc-consulting/sheriff):

- **`sheriff.config.ts`** en la raíz del proyecto define los límites entre capas.
- El plugin ESLint **`@softarc/eslint-plugin-sheriff`** valida los imports en cada fichero.
- Cualquier violación se reporta como **error de build en CI** (Jenkins pipeline).

## Path aliases

Definidos en `tsconfig.json` bajo `compilerOptions.paths`:

| Alias         | Ruta             |
| ------------- | ---------------- |
| `@app/*`      | `src/app/*`      |
| `@pages/*`    | `src/pages/*`    |
| `@widgets/*`  | `src/widgets/*`  |
| `@features/*` | `src/features/*` |
| `@entities/*` | `src/entities/*` |
| `@shared/*`   | `src/shared/*`   |

Cada capa expone su API pública a través de un fichero `index.ts` barrel. Los imports externos a una capa deben usar el barrel, nunca rutas internas.

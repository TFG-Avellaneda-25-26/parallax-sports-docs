---
title: Estructura del proyecto
description: Árbol de directorios completo del frontend Angular de Parallax Sports con la descripción de cada carpeta por capa FSD.
tags:
  - frontend
  - arquitectura
  - fsd
---

# Estructura del proyecto

La aplicación vive en `parallax-sports-angular/src/`. Cada capa de [[frontend/arquitectura-fsd|FSD]] tiene su propia carpeta de primer nivel.

## Árbol completo

```
src/
├── app/
│   ├── app.ts, app.html, app.css
│   ├── app.config.ts
│   └── app.routes.ts
├── pages/
│   ├── landing/
│   ├── auth/
│   ├── dashboard/
│   ├── settings/
│   └── error/
├── widgets/
│   ├── header/
│   └── settings-nav/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── event/
│   ├── settings/
│   └── theme-switch/
├── entities/
│   ├── auth/
│   ├── event/
│   ├── user/
│   ├── admin-user/
│   ├── audit/
│   ├── loadtest/
│   └── timezone/
└── shared/
    ├── api/
    ├── config/
    ├── interceptors/
    ├── lib/
    ├── models/
    ├── stores/
    └── ui/
```

## `app/`

| Fichero         | Contenido                                                                                                                             |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `app.config.ts` | `provideZonelessChangeDetection`, `provideRouter(routes)`, `provideHttpClient(withInterceptors([authInterceptor, errorInterceptor]))` |
| `app.routes.ts` | Árbol de rutas con lazy-loading mediante dynamic imports                                                                              |
| `app.ts`        | Componente raíz: importa `RouterOutlet` y `HeaderComponent`                                                                           |

## `pages/`

| Carpeta      | Descripción                                                                                                             |
| ------------ | ----------------------------------------------------------------------------------------------------------------------- |
| `landing/`   | `LandingPage`: héroe con GSAP MorphSVG (7 logos deportivos) y parallax con ScrollTrigger                                |
| `auth/`      | `AuthPage`: provee `AuthStore` a nivel de componente; renderiza `AuthFormComponent`                                     |
| `dashboard/` | `DashboardPage`: OnPush; sentinel ScrollTrigger para infinite scroll; alterna vista card/table vía `DashboardViewStore` |
| `settings/`  | `SettingsPage`: provee `SettingsNavStore`; sidebar `SettingsNavComponent` + `RouterOutlet` para sub-rutas               |
| `error/`     | `ErrorPage`: renderiza `ErrorDisplayComponent` con el `ProblemDetails` almacenado en `ErrorStore`                       |

## `widgets/`

| Carpeta         | Descripción                                                                                                                              |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `header/`       | `HeaderComponent`: animación de borde al montar (DrawSVG); aviso de verificación animado con TextPlugin; `ThemeToggleComponent` embebido |
| `settings-nav/` | `SettingsNavComponent`: árbol de navegación accesible con `@angular/aria` Tree; refleja el estado de `SettingsNavStore`                  |

## `features/`

| Carpeta         | Descripción                                                                                                     |
| --------------- | --------------------------------------------------------------------------------------------------------------- |
| `auth/`         | `AuthFormComponent`, `OtpDialogComponent`, `VerifyEmailDialogComponent`, `AuthStore`                            |
| `dashboard/`    | `DashboardToolbar`, `FilterDrawer`, `FilterTree`, `DashboardViewStore`, `EventFilterStore`, `FilterDrawerStore` |
| `event/`        | `EventCardComponent`, `EventCardGridComponent`, `EventTableComponent`, `EventStore`                             |
| `settings/`     | Sub-secciones `account/`, `preferences/`, `follows/`, `admin/` con sus propios formularios                      |
| `theme-switch/` | `ThemeToggleComponent`: View Transitions API ripple + MorphSVG sol↔luna                                         |

## `entities/`

| Carpeta       | Descripción                                                                                                                |
| ------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `auth/`       | `AuthModel`, `auth.schema.ts` (validaciones Zod/custom), `auth.service.ts`                                                 |
| `event/`      | `event.model.ts`, `event.service.ts`                                                                                       |
| `user/`       | `user.model.ts`, `UserStore` (providedIn: root), guards: `authGuard`, `redirectIfAuthenticatedGuard`, `verifiedEmailGuard` |
| `admin-user/` | Modelo e `admin-user.service.ts` para gestión de usuarios desde panel admin                                                |
| `audit/`      | Modelo e `audit.service.ts` para logs de auditoría                                                                         |
| `loadtest/`   | Modelo e `loadtest.service.ts` para resultados de k6 vía SSE                                                               |
| `timezone/`   | `timezone-options.model.ts`: lista de zonas horarias de `@vvo/tzdb`                                                        |

## `shared/`

| Carpeta         | Descripción                                                                                                                            |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `api/`          | `ApiClient`: wrapper sobre `HttpClient` que añade `withCredentials: true` a todas las peticiones                                       |
| `config/`       | Token de inyección `API_BASE_URL` configurado como `''` (mismo origen)                                                                 |
| `interceptors/` | `authInterceptor` (refresco de token 401), `errorInterceptor` (normalización a ProblemDetails)                                         |
| `lib/`          | `gsap.ts` (registro de plugins), `event-time.pipe.ts`, `format-event-time.ts`, `scroll-to-section.ts`                                  |
| `models/`       | `ProblemDetails` (RFC 7807), `settings-nav.model.ts`                                                                                   |
| `stores/`       | `ThemeStore`, `ErrorStore`, `SettingsNavStore`                                                                                         |
| `ui/`           | Componentes UI genéricos: `button`, `checkbox-icon`, `image-drag-and-drop`, `logo`, `spinner`, `stateful-input`, `stateful-combobox-*` |

### `shared/ui/styles/`

| Fichero            | Contenido                                                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `animation.css`    | Keyframes y clases de animación reutilizables                                                                                                    |
| `base.css`         | Reset y estilos base del documento                                                                                                               |
| `buttons.css`      | Variantes de botones                                                                                                                             |
| `fonts.css`        | `@font-face` y variables de tipografía                                                                                                           |
| `ng-otp-input.css` | Overrides de estilos para el componente `ng-otp-input`                                                                                           |
| `theme.css`        | Custom properties CSS para tema claro/oscuro (`--color-*`, `--bg-*`, etc.) definidas en `:root[data-theme="light"]` y `:root[data-theme="dark"]` |

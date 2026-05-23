---
title: Gestión de estado con NgRx Signals
description: "Stores NgRx Signals del frontend de Parallax Sports: estado, computed signals y métodos de cada store."
tags:
  - frontend
  - estado
  - ngrx
  - signals
---

# Gestión de estado con NgRx Signals

Todos los stores usan la API `signalStore` de `@ngrx/signals`. No existe NgRx Store clásico (reducers/actions/effects).

## UserStore

**Ubicación:** `entities/user/store`: `providedIn: root`

| Estado      | Tipo           |
| ----------- | -------------- |
| `user`      | `User \| null` |
| `isLoading` | `boolean`      |

**Computed:**

`isAuthenticated`, `isVerified`, `isAdmin`, `email`, `displayName`, `timezone`, `defaultView`, `dateFormat`, `linkedProviders`

**Métodos:**

| Método                 | Acción                                                         |
| ---------------------- | -------------------------------------------------------------- |
| `loadUser()`           | GET `/api/users/me`: carga el usuario autenticado              |
| `markEmailVerified()`  | Actualiza `user.emailVerified` en local sin petición adicional |
| `updateEmail()`        | PATCH `/api/users/email`                                       |
| `updatePassword()`     | PATCH `/api/users/password`                                    |
| `updateDisplayName()`  | PATCH `/api/users/display-name`                                |
| `disconnectIdentity()` | DELETE `/api/users/identities/{provider}`                      |
| `linkIdentity()`       | Inicia flujo OAuth2 de vinculación                             |
| `deleteAccount()`      | DELETE `/api/users/me`                                         |
| `updateTimeZone()`     | PATCH `/api/users/timezone`                                    |

---

## AuthStore

**Ubicación:** `features/auth/store`: provisto a nivel de componente en `AuthPage`

| Estado | Tipo                    |
| ------ | ----------------------- |
| `mode` | `'login' \| 'register'` |

**Computed:**

`isRegisterMode`, `formSubmissionText`, `formButtonText`, `authErrorSubmitMessage`

**Propiedades y métodos:**

- `authForm`: signal form con campos que varían según `mode` (ver [[frontend/formularios-signal|Formularios Signal]])
- `toggleMode()`: alterna entre login y register

Al completar la autenticación con éxito: llama a `UserStore.loadUser()` y navega a `/dashboard`.

---

## EventStore

**Ubicación:** `features/event/store`: `providedIn: root`

| Estado       | Tipo             |
| ------------ | ---------------- |
| `events`     | `SportEvent[]`   |
| `nextCursor` | `number \| null` |
| `hasMore`    | `boolean`        |
| `isLoading`  | `boolean`        |

**Métodos:**

| Método                | Acción                                                                          |
| --------------------- | ------------------------------------------------------------------------------- |
| `loadInitialEvents()` | GET `/api/events` con ventana de 3 meses desde hoy; llamado por `eventResolver` |
| `loadMore()`          | GET `/api/events?cursor={nextCursor}`: paginación cursor-based                  |
| `clearEvents()`       | Vacía el estado local                                                           |

---

## DashboardViewStore

**Ubicación:** `features/dashboard/store`: `providedIn: root`

| Estado | Tipo                 |
| ------ | -------------------- |
| `view` | `'cards' \| 'table'` |

**Hook `onInit`:** lee `UserStore.userPreferences().defaultView` para inicializar la vista preferida del usuario.

---

## EventFilterStore

**Ubicación:** `features/dashboard/store`: `providedIn: root`

Estado: 8 señales `Set<string>`:

| Señal                 | Propósito                         |
| --------------------- | --------------------------------- |
| `includeSports`       | Deportes incluidos explícitamente |
| `excludeSports`       | Deportes excluidos explícitamente |
| `includeCompetitions` | Competiciones incluidas           |
| `excludeCompetitions` | Competiciones excluidas           |
| `includeEventTypes`   | Tipos de evento incluidos         |
| `excludeEventTypes`   | Tipos de evento excluidos         |
| `includeParticipants` | Participantes incluidos           |
| `excludeParticipants` | Participantes excluidos           |

**Métodos clave:**

- `eventPasses(event)`: filtro jerárquico: deporte → competición → tipo de evento → participante
- `buildTree(events)`: deriva `SportNode[]` para `FilterTreeComponent`

Las claves compuestas usan el formato `sportKey::competitionName::id`.

---

## FilterDrawerStore

**Ubicación:** `features/dashboard/store`: `providedIn: root`

| Estado   | Tipo      |
| -------- | --------- |
| `isOpen` | `boolean` |

> El campo se llama `isOpen` y **no** `open` para evitar una colisión de nombres con la API interna de NgRx Signals. Ver [[diario/dificultades]] para el detalle.

**Métodos:** `open()`, `close()`, `toggle()`

---

## ThemeStore

**Ubicación:** `shared/stores`: `providedIn: root`

| Estado  | Tipo                |
| ------- | ------------------- |
| `theme` | `'light' \| 'dark'` |

**Hook `onInit`:** prioridad de inicialización:

1. `localStorage.getItem('theme')`
2. Atributo `data-theme` en el elemento `<html>`
3. `window.matchMedia('(prefers-color-scheme: dark)')`

**Effect:** en cada cambio de `theme`:

- `document.documentElement.setAttribute('data-theme', theme)`
- `localStorage.setItem('theme', theme)`

---

## ErrorStore

**Ubicación:** `shared/stores`: `providedIn: root`

| Estado  | Tipo                     |
| ------- | ------------------------ |
| `error` | `ProblemDetails \| null` |

**Métodos:** `set(error: ProblemDetails)`, `clear()`

`ErrorPage` consume este store para mostrar el detalle del error al usuario.

---

## SettingsNavStore

**Ubicación:** `shared/stores`: provisto a nivel de componente en `SettingsPage`

| Estado     | Tipo         |
| ---------- | ------------ |
| `tree`     | `TreeNode[]` |
| `selected` | `string[]`   |

**Computed:** `flatNodes`, `activeSectionId`

El árbol se inicializa con la constante estática `SETTINGS_TREE` (4 nodos: Account, Preferences, Notifications, Admin).

## Fuentes

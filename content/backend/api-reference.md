---
title: Referencia de la API
description: Tabla completa de endpoints REST del backend de Parallax Sports agrupados por módulo.
tags: [backend, api, rest]
---

# Referencia de la API

## Autenticación: `/api/auth`

Acceso: **Público**

| Método | Ruta                               | Descripción                                   |
| ------ | ---------------------------------- | --------------------------------------------- |
| POST   | `/register`                        | Registro de nueva cuenta                      |
| POST   | `/login`                           | Login email/contraseña → par JWT              |
| POST   | `/refresh`                         | Rotación de refresh token                     |
| POST   | `/logout`                          | Revocación de refresh token                   |
| POST   | `/verify-email`                    | Verificación de email con código de 6 dígitos |
| POST   | `/resend-verification`             | Reenvío del código de verificación            |
| DELETE | `/identities/{provider}/{subject}` | Desvincula una identidad social               |

---

## Usuarios: `/api/users`

Acceso: **Autenticado**

| Método | Ruta                 | Descripción                                                |
| ------ | -------------------- | ---------------------------------------------------------- |
| GET    | `/me`                | Perfil del usuario autenticado                             |
| GET    | `/email`             | Email del usuario autenticado                              |
| PUT    | `/email`             | Cambio de email                                            |
| PUT    | `/password`          | Cambio de contraseña                                       |
| PUT    | `/display-name`      | Cambio de nombre visible                                   |
| POST   | `/validate-password` | Valida la contraseña actual antes de operaciones sensibles |
| DELETE | `/me`                | Borrado de cuenta propia                                   |
| DELETE | `/identities/{id}`   | Desvincula identidad social por ID                         |

### Configuración de usuario: `/api/users/settings`

| Método | Ruta            | Descripción                                     |
| ------ | --------------- | ----------------------------------------------- |
| PUT    | `/timezone`     | Actualiza zona horaria                          |
| PUT    | `/default-view` | Actualiza vista por defecto (`cards` / `table`) |
| PUT    | `/date-format`  | Actualiza formato de fecha                      |
| POST   | `/init`         | Inicializa settings con valores por defecto     |

### Canales de notificación: `/api/users/notification-channels`

| Método | Ruta                   | Descripción                            |
| ------ | ---------------------- | -------------------------------------- |
| GET    | `/`                    | Lista canales del usuario              |
| PUT    | `/{sportId}/{channel}` | Activa/configura canal para un deporte |
| DELETE | `/{sportId}/{channel}` | Desactiva canal para un deporte        |

---

## Eventos deportivos

Acceso: **Público**

| Método | Ruta                            | Parámetros                                          | Descripción            |
| ------ | ------------------------------- | --------------------------------------------------- | ---------------------- |
| GET    | `/api/formula1/sessions/{year}` |:                                                   | Sesiones F1 de un año  |
| GET    | `/api/basketball/games`         | `startDate`, `endDate`, `league`                    | Partidos de baloncesto |
| GET    | `/api/basketball/teams`         |:                                                   | Equipos NBA/WNBA       |
| GET    | `/api/{game}/matches`           | game: `lol`, `valorant`, `dota2`, `cs`, `overwatch` | Partidos de esports    |

---

## Admin: Usuarios: `/api/admin/users`

Acceso: **ADMIN**

| Método | Ruta                 | Descripción                         |
| ------ | -------------------- | ----------------------------------- |
| GET    | `/`                  | Búsqueda paginada de usuarios       |
| GET    | `/{id}`              | Obtiene usuario por ID              |
| PUT    | `/{id}/email`        | Cambia email de un usuario          |
| PUT    | `/{id}/display-name` | Cambia nombre visible de un usuario |
| PUT    | `/{id}/verify`       | Marca email como verificado         |
| PUT    | `/{id}/role`         | Cambia rol del usuario              |
| DELETE | `/{id}`              | Elimina un usuario                  |

## Admin: Eventos: `/api/admin/events`

Acceso: **ADMIN**

| Método | Ruta      | Descripción                                          |
| ------ | --------- | ---------------------------------------------------- |
| POST   | `/inject` | Inyección manual de evento (`EventInjectionRequest`) |

## Admin: Sincronización: `/api/admin`

Acceso: **ADMIN**

| Método | Ruta                      | Descripción                    |
| ------ | ------------------------- | ------------------------------ |
| POST   | `/sync/daily/trigger`     | Ejecuta todos los jobs de sync |
| POST   | `/basketball/sync`        | Sync solo basketball           |
| POST   | `/formula1/sync/{year}`   | Sync F1 para un año específico |
| POST   | `/pandascore/sync/{game}` | Sync esport específico         |

## Admin: Auditoría: `/api/admin/audit`

Acceso: **ADMIN**

| Método | Ruta | Parámetros                                        | Descripción                      |
| ------ | ---- | ------------------------------------------------- | -------------------------------- |
| GET    | `/`  | `actor`, `action`, `entity`, `dateFrom`, `dateTo` | Registros de auditoría paginados |

## Admin: Load tests: `/api/admin/loadtest`

Acceso: **ADMIN**

| Método | Ruta              | Descripción                           |
| ------ | ----------------- | ------------------------------------- |
| GET    | `/scenarios`      | Lista escenarios de carga disponibles |
| POST   | `/runs`           | Inicia una ejecución de carga         |
| GET    | `/runs/{id}`      | Estado de una ejecución               |
| POST   | `/runs/{id}/stop` | Detiene una ejecución activa          |
| GET    | `/runs/{id}/logs` | Stream SSE de logs en tiempo real     |

---

## Interno: `/api/internal`

Acceso: **API Key** (verificada en controller)

| Método | Ruta                         | Descripción                                               |
| ------ | ---------------------------- | --------------------------------------------------------- |
| GET    | `/render/event/{eventId}`    | Renderiza HTML del evento con Thymeleaf (para artefactos) |
| POST   | `/alerts/{alertId}/status`   | Callback de worker: reporta estado de procesamiento       |
| POST   | `/alerts/{alertId}/artifact` | Callback de worker: sube URL de artefacto generado        |

### Interno Discord: `/api/internal/discord`

| Método | Ruta                                        | Descripción                                 |
| ------ | ------------------------------------------- | ------------------------------------------- |
| POST   | `/guilds/install`                           | Registra instalación del bot en un servidor |
| DELETE | `/guilds/{guildId}`                         | Elimina configuración de un servidor        |
| POST   | `/guilds/{guildId}/channel`                 | Establece canal por defecto del servidor    |
| GET    | `/users/by-discord/{discordUserId}`         | Busca usuario por ID de Discord             |
| PUT    | `/users/{userId}/delivery`                  | Configura preferencia de entrega Discord    |
| DELETE | `/users/{userId}/delivery`                  | Elimina preferencia de entrega Discord      |
| PUT    | `/users/{userId}/delivery/sports/{sportId}` | Override de entrega por deporte (ID)        |
| DELETE | `/users/{userId}/delivery/sports/{sportId}` | Elimina override por deporte (ID)           |
| PUT    | `/users/{userId}/delivery/sport-keys/{key}` | Override de entrega por clave de deporte    |
| DELETE | `/users/{userId}/delivery/sport-keys/{key}` | Elimina override por clave de deporte       |

---

## Bot: `/api/bot`

Acceso: **API Key** (`BotApiKeyFilter`)

| Método | Ruta                | Descripción                                                      |
| ------ | ------------------- | ---------------------------------------------------------------- |
| GET    | `/check-permission` | Comprueba si un usuario Discord tiene permiso para una operación |

## Fuentes

---
title: Sincronización de datos
description: Jobs de ingesta diaria de datos deportivos desde OpenF1, BallDontLie y PandaScore en Parallax Sports.
tags: [backend, sincronizacion, external-api, formula1, basketball, esports]
---

# Sincronización de datos

## Fuentes

- [PandaScore API – Introducción](https://developers.pandascore.co/docs/introduction)
- [PandaScore API – Referencia](https://developers.pandascore.co/reference/get_additions)
- [OpenF1 API](https://openf1.org/docs/#api-endpoints)
- [BallDontLie NBA/WNBA API](https://nba.balldontlie.io/#nba-api)
- [Spring: RestClient](https://docs.spring.io/spring-framework/reference/integration/rest-clients.html#rest-webclient)
- [PostgreSQL UPSERT – GeeksForGeeks](https://www.geeksforgeeks.org/postgresql/postgresql-upsert/)

---

## Arquitectura común

Cada proveedor implementa la interfaz `ExternalApiDailySyncJob`. El scheduler central `ExternalApiDailyScheduler` los ejecuta todos con cron `0 30 0 * * *` (00:30 UTC diario).

`SyncWriteHelper` centraliza la lógica de upsert usando `external_id` como clave de deduplicación: si el evento ya existe se actualiza, si no se inserta.

Tras completar cada job, se publica `EventsIngestedEvent` (Spring application event, `AFTER_COMMIT`) que dispara la generación de alertas. Ver [[sistema-alertas|Sistema de alertas]].

---

## Formula 1: OpenF1

**API base:** `https://api.openf1.org/v1`  
**Sport key:** `formula1`

| Endpoint              | Datos                                               |
| --------------------- | --------------------------------------------------- |
| `/v1/meetings?year=X` | Eventos padre (Gran Premios)                        |
| `/v1/sessions?year=X` | Sesiones hijas (qualifying, race, sprint, practice) |

- Los `meetings` se sincronizan como `Event` con `parent_event_id=null`.
- Las `sessions` se sincronizan como `Event` con `parent_event_id` apuntando al meeting.
- `event_type`: `race`, `qualifying`, `sprint`, `practice`.
- **Venues:** se derivan del campo `location`/`circuit` del meeting.
- **Participantes (pilotos/constructores):** no se sincronizan desde OpenF1.

**Triggers manuales:**

- `POST /api/admin/formula1/sync/{year}`: sincroniza un año específico.

---

## Basketball: BallDontLie

**API base:** `https://api.balldontlie.io`  
**Autenticación:** API key en cabecera.

| Endpoint                     | Datos         |
| ---------------------------- | ------------- |
| `/v1/games?seasons[]=X`      | Partidos NBA  |
| `/v1/wnba/games?seasons[]=X` | Partidos WNBA |

**Sport keys:** `basketball_nba`, `basketball_wnba`

- **Competiciones:** NBA y WNBA se crean como `Competition` con `kind=league`.
- **Participantes:** los equipos se sincronizan como `Participant` con `kind=team`.
- **Configuración de rango temporal:** `years_back=0`, `years_forward=1` (temporada actual + siguiente).

**Triggers manuales:**

- `POST /api/admin/basketball/sync`: sincronización completa de baloncesto.

---

## Esports: PandaScore

**API base:** `https://api.pandascore.co`  
**Autenticación:** API key en cabecera.

| Deporte           | Endpoint de partidos |
| ----------------- | -------------------- |
| League of Legends | `/lol/matches`       |
| Valorant          | `/valorant/matches`  |
| Dota 2            | `/dota2/matches`     |
| Counter-Strike    | `/csgo/matches`      |
| Overwatch         | `/overwatch/matches` |

- Se sincronizan torneos, series y partidos.
- **Participantes:** equipos con logos (almacenados como `MediaAsset`).

**Triggers manuales:**

- `POST /api/admin/pandascore/sync/{game}`: sincroniza un esport específico (`lol`, `valorant`, `dota2`, `csgo`, `overwatch`).

---

## Triggers de administración

| Endpoint                                 | Acción                  |
| ---------------------------------------- | ----------------------- |
| `POST /api/admin/sync/daily/trigger`     | Ejecuta todos los jobs  |
| `POST /api/admin/basketball/sync`        | Solo basketball         |
| `POST /api/admin/formula1/sync/{year}`   | F1 para un año concreto |
| `POST /api/admin/pandascore/sync/{game}` | Un esport concreto      |

---

## EventsIngestedEvent

Evento Spring publicado tras cada sync exitoso.

- Implementado con `@TransactionalEventListener(phase = AFTER_COMMIT)`.
- Garantiza que los eventos están comprometidos en BD antes de generar alertas.
- `UserEventAlertGenerationService` procesa el evento para crear o actualizar `UserEventAlert` por cada usuario seguidor.

---
title: Sincronización de datos externos
description: "Ingesta diaria desde OpenF1, BallDontLie y PandaScore hacia PostgreSQL con deduplicación y triggers de alertas"
tags: [flujos, sync, datos, openf1, balldontlie, pandascore, scheduler]
---

# Sincronización de datos externos

`ExternalApiDailyScheduler` orquesta la ingesta diaria de eventos deportivos desde tres proveedores externos hacia PostgreSQL.

## Scheduler

- **Cron:** `0 30 0 * * *` → 00:30 UTC
- Ejecuta todos los beans que implementan `ExternalApiDailySyncJob`.
- Cada job devuelve `ExternalSyncExecutionResult`:

```
ExternalSyncExecutionResult {
  upserted: int
  skipped: int
  failed: int
}
```

Tras el commit de cada job se publica un `EventsIngestedEvent` mediante `@TransactionalEventListener(AFTER_COMMIT)`, que desencadena la generación de alertas. Ver [[entrega-alertas|flujo de entrega de alertas]].

## Proveedores

### Formula 1: OpenF1

```
GET https://api.openf1.org/v1/meetings?year={year}
  → upsert competitions + venues

GET https://api.openf1.org/v1/sessions?year={year}
  → upsert events
    parent = competition (meeting)
    type   = race | qualifying | sprint | practice
```

### Baloncesto: BallDontLie

```
# NBA
GET https://api.balldontlie.io/v1/teams
  → upsert participants (equipos)

GET https://api.balldontlie.io/v1/games?seasons[]={year}
  → upsert events (partidos NBA)

# WNBA
GET https://api.balldontlie.io/v1/wnba/teams
GET https://api.balldontlie.io/v1/wnba/games?seasons[]={year}
  → mismo proceso para WNBA
```

### Esports: PandaScore

```
GET https://api.pandascore.co/{game}/matches
  → upsert teams        (participants)
  → upsert tournaments  (competitions)
  → upsert matches      (events)
```

Juegos soportados: `lol`, `valorant`, `dota2`, `csgo`, `overwatch`

## Deduplicación: SyncWriteHelper

Todos los jobs usan `SyncWriteHelper` para gestionar los upserts.

- **Clave compuesta:** `external_provider` + `external_id`
- Registros **existentes:** se actualizan (status, times, participants).
- Registros **nuevos:** se insertan.
- Sin duplicados aunque el scheduler se ejecute varias veces el mismo día.

## EventsIngestedEvent

Publicado por `@TransactionalEventListener(AFTER_COMMIT)` tras cada sync job exitoso.

`UserEventAlertGenerationService` consume este evento para calcular y crear las `user_event_alerts` correspondientes.

## Triggers manuales (admin)

Endpoints disponibles para forzar una sincronización sin esperar al cron:

| Endpoint                                 | Alcance                      |
| ---------------------------------------- | ---------------------------- |
| `POST /api/admin/sync/daily/trigger`     | Todos los jobs               |
| `POST /api/admin/basketball/sync`        | Solo baloncesto (NBA + WNBA) |
| `POST /api/admin/formula1/sync/{year}`   | F1 de un año específico      |
| `POST /api/admin/pandascore/sync/{game}` | Un esport específico         |

---
title: Entrega de alertas
description: "Flujo end-to-end desde la sincronización de datos externos hasta la entrega de una alerta por Discord o email"
tags: [flujos, alertas, arquitectura, redis, ktor, spring]
---

# Entrega de alertas

Flujo completo de cinco fases que va desde la ingesta de datos de APIs externas hasta la confirmación de entrega de una notificación al usuario.

## Actores

| Actor                       | Responsabilidad                                           |
| --------------------------- | --------------------------------------------------------- |
| `ExternalApiDailyScheduler` | Dispara la sincronización diaria a las 00:30 UTC          |
| Angular SPA                 | Interfaz del usuario                                      |
| Spring API                  | Orquestador principal: generación y dispatch de alertas   |
| PostgreSQL                  | Almacenamiento persistente de eventos, alertas y usuarios |
| Redis Stream                | Bus de mensajes (`alerts.{channel}.v1`)                   |
| Ktor Worker                 | Consumidor del stream; llama a providers externos         |
| ms-playwright               | Generación de capturas de pantalla                        |
| ms-cloudinary               | Almacenamiento y caché de artefactos                      |
| Discord / Gmail API         | Entrega final de la notificación                          |

## Diagrama de secuencia

```mermaid
sequenceDiagram
    participant Sched as ExternalApiDailyScheduler
    participant DB as PostgreSQL
    participant Spring as Spring API
    participant Redis as Redis Stream
    participant Ktor as Ktor Worker
    participant PW as ms-playwright
    participant Cloud as ms-cloudinary
    participant Prov as Discord / Gmail

    rect rgb(220,235,255)
        Note over Sched,DB: Fase 1: Sincronización diaria (00:30 UTC)
        Sched->>DB: Upsert events (OpenF1 / BallDontLie / PandaScore)
        DB-->>Sched: OK
        Sched->>Spring: EventsIngestedEvent (after-commit)
    end

    rect rgb(255,240,220)
        Note over Spring,DB: Fase 2: Generación de alertas
        Spring->>DB: Resolver pares (usuario, canal) por follow settings
        Spring->>DB: Upsert user_event_alerts (send_at_utc, idempotency_key)
    end

    rect rgb(220,255,230)
        Note over Spring,Redis: Fase 3: Dispatch (cada minuto)
        Spring->>DB: SELECT FOR UPDATE SKIP LOCKED: alertas vencidas
        alt artifact_required y sin artefacto
            Spring-->>Spring: Skip: esperar artefacto
        else alerta enrutable
            Spring->>Redis: XADD alerts.{channel}.v1 * ...campos...
        end
    end

    rect rgb(255,255,215)
        Note over Ktor,Prov: Fase 4: Procesado Ktor
        Ktor->>Redis: XREADGROUP BLOCK 5000 COUNT 3
        alt artifact_required = true
            Ktor->>PW: POST /api/internal/screenshot
            PW->>Cloud: Check caché / upload PNG
            Cloud-->>PW: URL del artefacto
            PW-->>Ktor: PlaywrightResponse { url }
        end
        Ktor->>Prov: Enviar mensaje (+ artefacto opcional)
        Ktor->>Redis: XACK + XDEL
        Ktor->>Spring: POST /api/internal/alerts/{id}/status
    end

    rect rgb(245,225,255)
        Note over Spring,DB: Fase 5: Callback
        Spring->>DB: Crea AlertDeliveryAttempt
        Spring->>DB: Actualiza UserEventAlert.status
    end
```

## Fase 1: Sincronización diaria

`ExternalApiDailyScheduler` se ejecuta a las **00:30 UTC** mediante cron `0 30 0 * * *`.

Lanza todos los `ExternalApiDailySyncJob` registrados. Cada job:

- Consulta su API externa (OpenF1, BallDontLie, PandaScore)
- Realiza upsert de events en PostgreSQL
- Devuelve `ExternalSyncExecutionResult` con contadores `upserted / skipped / failed`

Tras el commit de cada job se publica `EventsIngestedEvent` vía `@TransactionalEventListener(AFTER_COMMIT)`.

Ver detalle en [[sincronizacion-datos|Sincronización de datos externos]].

## Fase 2: Generación de alertas

`UserEventAlertGenerationService` escucha `EventsIngestedEvent`.

Para cada evento ingestado:

1. Resuelve los pares elegibles `(usuario, canal)` en función de los follow settings del usuario.
2. Calcula `send_at_utc = event.start_time_utc - lead_time_minutes`.
3. Hace upsert en `user_event_alerts` usando `idempotency_key` para evitar duplicados.

## Fase 3: Dispatch scheduler

`UserEventAlertDispatchScheduler` se ejecuta **cada minuto**.

1. `SELECT FOR UPDATE SKIP LOCKED`: obtiene alertas cuyo `send_at_utc ≤ now()`.
2. Si `artifact_required = true` y no hay artefacto disponible → **skip** (reintentará en el siguiente ciclo).
3. Para Discord: `DiscordRoutingResolver` calcula el destino (DM vs canal de guild). Si no es enrutable → `failed_permanent`.
4. Publica en Redis Stream: `XADD alerts.{channel}.v1 * ...campos...`

## Fase 4: Procesado por Ktor Worker

`RedisStreamConsumer` en el módulo Ktor:

1. `XREADGROUP BLOCK 5000 COUNT 3`: lee hasta 3 mensajes del grupo de consumo.
2. Si `artifactRequired = true` → llama a `PlaywrightClient`. Ver [[pipeline-artefactos|pipeline de artefactos]].
3. `sendToProvider(message, artifactUrl)`: envía al proveedor final.
4. `XACK + XDEL`: confirma el mensaje **antes** del callback a Spring.
5. `POST /api/internal/alerts/{id}/status` con `sent` o `failed_*`.

## Fase 5: Callback a Spring

`AlertCallbackService`:

1. Valida la transición de estado (sent / failed_permanent / failed_retryable).
2. Crea un registro `AlertDeliveryAttempt`.
3. Actualiza el estado final en `UserEventAlert`.

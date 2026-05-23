---
title: Contrato Redis Streams
description: Protocolo productor-consumidor entre Spring Boot y los workers Ktor para el despacho de alertas vía Redis Streams.
tags: [backend, redis, streams, protocolo, microservicios]
---

# Contrato Redis Streams

## Fuentes

- [Redis: Pub/Sub](https://redis.io/docs/latest/develop/pubsub/)

---

Define el protocolo entre el productor (Spring Boot) y los consumidores (workers Ktor) para el despacho de alertas.

---

## Streams por canal

| Stream               | Consumer Group     | Worker          |
| -------------------- | ------------------ | --------------- |
| `alerts.discord.v1`  | `discord-workers`  | `ms-discord`    |
| `alerts.email.v1`    | `email-workers`    | `ms-email`      |
| `alerts.telegram.v1` | `telegram-workers` | _(placeholder)_ |

---

## Payload v1

Todos los campos son `String`. Booleanos como `"true"` / `"false"`. Campos opcionales pueden estar ausentes.

### Campos comunes

| Campo              | Tipo                 | Notas                            |
| ------------------ | -------------------- | -------------------------------- |
| `alertId`          | String UUID          | ID de `UserEventAlert`           |
| `channel`          | String               | `discord` / `email` / `telegram` |
| `attempts`         | String int           | Número de intento actual         |
| `maxAttempts`      | String int           | Máximo de intentos (6)           |
| `idempotencyKey`   | String               | Clave única de deduplicación     |
| `schemaVersion`    | String               | Siempre `v1`                     |
| `sendAtUtc`        | String ISO-8601      | Momento programado de envío      |
| `artifactRequired` | String boolean       | Si se requiere artefacto visual  |
| `artifactId`       | String UUID opcional | Presente si ya existe artefacto  |

### Campos del evento

| Campo             | Tipo                     | Notas                    |
| ----------------- | ------------------------ | ------------------------ |
| `eventId`         | String UUID              |                          |
| `eventName`       | String                   | Nombre del evento        |
| `eventType`       | String                   | `race`, `match`, etc.    |
| `eventStatus`     | String                   | Estado actual del evento |
| `startTimeUtc`    | String ISO-8601          |                          |
| `endTimeUtc`      | String ISO-8601 opcional |                          |
| `sportKey`        | String                   | Ej. `formula1`           |
| `competitionName` | String                   |                          |
| `venueName`       | String                   |                          |
| `venueTimezone`   | String                   | IANA tz                  |

### Campos del usuario

| Campo            | Tipo            | Notas                                            |
| ---------------- | --------------- | ------------------------------------------------ |
| `userId`         | String UUID     |                                                  |
| `userEmail`      | String          |                                                  |
| `userTimezone`   | String nullable |                                                  |
| `userDateFormat` | String          | Definido en DTO, no mapeado desde BD actualmente |

### Campos específicos de Discord

| Campo                 | Tipo            | Notas                     |
| --------------------- | --------------- | ------------------------- |
| `discordDeliveryMode` | String          | `DM` / `GUILD_CHANNEL`    |
| `discordUserId`       | String opcional | ID de Discord del usuario |
| `discordChannelId`    | String opcional | Canal destino             |
| `discordGuildId`      | String opcional | Servidor destino          |

### Campos de deduplicación de artefacto

| Campo        | Notas                                                                               |
| ------------ | ----------------------------------------------------------------------------------- |
| `renderHash` | Hash del contexto de renderizado; permite al worker reutilizar artefactos idénticos |

### Campos gestionados por el consumidor

Estos campos **no los establece el productor**; el worker los rellena en su estado interno:

| Campo             | Notas                                           |
| ----------------- | ----------------------------------------------- |
| `streamMessageId` | ID del mensaje Redis asignado al ACK            |
| `workerId`        | Identificador del worker que procesa el mensaje |

---

## Semántica at-least-once

- `XREADGROUP` con `BLOCK 5000` ms y `COUNT 3` mensajes por ciclo.
- El consumidor hace `XACK` y `XDEL` **antes** de invocar el callback HTTP a Spring (no después), evitando reprocesamientos por timeout del callback.
- Las _pending entries_ se reclaman tras `idle_timeout` configurable.
- Los mensajes que superan `max_delivery_count` se mueven a un stream DLQ (_Dead Letter Queue_) por canal.

---

## Versionado de esquema

El campo `schemaVersion=v1` permite a los consumidores detectar el formato del payload y adaptarse a futuras versiones sin romper compatibilidad hacia atrás. Adiciones de campos nuevos en v1 son no-breaking (consumidores ignorarán campos desconocidos).

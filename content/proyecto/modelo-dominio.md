---
title: Modelo de dominio
description: Jerarquía de entidades de Parallax Sports: Sports, Competitions, Events, Participants, Users y Alerts.
tags: [proyecto, dominio, base-de-datos]
aliases: [dominio, entidades]
---

# Modelo de dominio

## Jerarquía de eventos deportivos

```
Sport (ej. "Formula 1", "NBA", "League of Legends")
 └── Competition (ej. "Temporada 2025 F1", "NBA Regular Season 2024-25")
      └── Season (ej. "2025", "2024-25")
           └── Event (ej. "GP Australia 2025", "Lakers vs Warriors")
                ├── parent_event_id → Event (ej. Qualifying es hijo de GP Weekend)
                └── EventEntry → Participant (ej. "Max Verstappen", "Los Angeles Lakers")
```

Un `Event` puede tener hijos: en F1, el Grand Prix Weekend (`parent_event`) contiene los `Session` hijos (Practice 1, Qualifying, Race). En esports, un torneo contiene sus partidas individuales.

## Entidades principales

### Sport

Categoría de alto nivel. Cada deporte tiene una clave única (`key`) usada para routing interno.

| Campo  | Tipo        | Notas                                     |
| ------ | ----------- | ----------------------------------------- |
| `id`   | bigserial   | PK                                        |
| `key`  | text UNIQUE | `formula1`, `nba`, `wnba`, `esports-lol`… |
| `name` | text        | Nombre visible                            |

### Competition

Liga, torneo o serie dentro de un deporte.

| Campo                | Tipo | Notas                            |
| -------------------- | ---- | -------------------------------- |
| `kind`               | text | `league`, `tournament`, `series` |
| `region` / `country` | text | Procedencia geográfica           |

### Season

Edición temporal de una Competition.

### Venue

Lugar físico o virtual donde ocurre el evento.

| Campo      | Tipo | Notas                                                      |
| ---------- | ---- | ---------------------------------------------------------- |
| `kind`     | text | `stadium`, `circuit`, `arena`, `other`                     |
| `timezone` | text | Zona horaria IANA del recinto: usada para localizar horas |

### Event

Evento concreto con fecha y estado.

| Campo               | Tipo           | Notas                                                     |
| ------------------- | -------------- | --------------------------------------------------------- |
| `event_type`        | text           | `race`, `qualifying`, `match`, `session`…                 |
| `status`            | text           | `scheduled`, `live`, `finished`, `cancelled`, `postponed` |
| `start_time_utc`    | timestamptz    | Inicio en UTC                                             |
| `parent_event_id`   | bigint FK self | Eventos hijos (sesiones F1)                               |
| `participants_mode` | text           | `none`, `teams`, `field`                                  |
| `external_provider` | text           | `openf1`, `balldontlie`, `pandascore-lol`…                |
| `external_id`       | text           | ID en el sistema origen: clave de deduplicación          |

### Participant

Equipo, piloto, atleta o constructor.

| Campo        | Tipo | Notas                                     |
| ------------ | ---- | ----------------------------------------- |
| `kind`       | text | `team`, `athlete`, `constructor`, `other` |
| `short_name` | text | Abreviatura para mostrar en tarjetas      |

### EventEntry

Une un `Participant` con un `Event` con su rol en ese evento.

| Campo           | Tipo | Notas                         |
| --------------- | ---- | ----------------------------- |
| `side`          | text | `home`, `away`, `blue`, `red` |
| `display_order` | int  | Orden visual en la tarjeta    |

### MediaAsset

Imágenes asociadas a entidades (logos de equipos, iconos de sport, banners).

| Campo                     | Tipo          | Notas                             |
| ------------------------- | ------------- | --------------------------------- |
| `owner_type` / `owner_id` | text / bigint | Entidad propietaria (polimórfico) |
| `asset_type`              | text          | `logo`, `icon`, `banner`, `photo` |

---

## Usuarios y configuración

```
User
 ├── UserSettings         (preferencias: timezone, tema, vista por defecto)
 ├── UserIdentity[]       (OAuth: Google / Discord)
 ├── UserSportFollow[]    (seguir competición o participante específico)
 ├── UserSportSettings[]  (config por deporte: follow-all, event_type_filter, notify_default)
 └── UserSportNotificationChannel[] (activar/desactivar canal por deporte)
```

### UserSportFollow

El usuario declara explícitamente que sigue una competición o participante dentro de un deporte.

| Campo               | Notas                                                              |
| ------------------- | ------------------------------------------------------------------ |
| `follow_type`       | `competition` o `participant`                                      |
| `event_type_filter` | Array: filtra por tipos de evento (ej. solo `race`, no `practice`) |
| `notify`            | Activa notificaciones para ese follow                              |

### UserSportSettings

Configuración global por deporte (sin follow específico).

| Campo            | Notas                                                           |
| ---------------- | --------------------------------------------------------------- |
| `follow_all`     | Si está activo, recibe alertas de todos los eventos del deporte |
| `notify_default` | Canal de notificación por defecto para este deporte             |

---

## Alertas

```
UserEventAlert
 ├── AlertDeliveryAttempt[]  (historial de intentos por intento N)
 └── AlertArtifact           (imagen generada con Playwright + Cloudinary)
```

### UserEventAlert: Máquina de estados

```
scheduled
  └── queued
       └── processing
            ├── sent (terminal ✓)
            ├── failed_retryable → reintento → queued
            └── failed_permanent (terminal ✗)

waiting_artifact  →  scheduled  (cuando el artefacto está listo)
cancelled (terminal: evento cancelado o postponed)
```

### AlertArtifact

Imagen PNG generada para el evento, almacenada en Cloudinary. Identificada por `render_context_hash` (SHA-256 del contexto de renderizado) para evitar generar la misma imagen dos veces.

---

## Esquema SQL

El esquema completo está en [`assets/schema.sql`](../assets/schema.sql).

## Fuentes

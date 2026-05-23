---
title: Modelo de datos
description: Entidades JPA del backend de Parallax Sports con sus campos principales y relaciones.
tags: [backend, base-de-datos, jpa, entidades]
---

# Modelo de datos

Esquema completo en [[assets/schema.sql|schema SQL completo]].

---

## User

| Campo            | Tipo             | Notas                          |
| ---------------- | ---------------- | ------------------------------ |
| `id`             | UUID PK          |                                |
| `email`          | varchar unique   | Identificador de login         |
| `password_hash`  | varchar nullable | Null para usuarios OAuth puros |
| `display_name`   | varchar          |                                |
| `role`           | enum             | `USER` / `ADMIN`               |
| `email_verified` | boolean          |                                |
| `created_at`     | timestamptz      |                                |
| `last_login_at`  | timestamptz      |                                |

---

## UserIdentity

Vincula cuentas sociales a un usuario local.

| Campo               | Tipo           | Notas                    |
| ------------------- | -------------- | ------------------------ |
| `id`                | UUID PK        |                          |
| `user_id`           | UUID FK → User |                          |
| `provider`          | enum           | `GOOGLE` / `DISCORD`     |
| `provider_subject`  | varchar        | ID externo del proveedor |
| `provider_username` | varchar        |                          |
| `provider_email`    | varchar        |                          |

Restricción unique: `(provider, provider_subject)`.

---

## UserSettings

| Campo          | Tipo              | Notas             |
| -------------- | ----------------- | ----------------- |
| `user_id`      | UUID PK/FK → User |                   |
| `theme`        | varchar           |                   |
| `default_view` | enum              | `cards` / `table` |
| `timezone`     | varchar           | IANA tz           |
| `date_format`  | varchar           |                   |
| `updated_at`   | timestamptz       |                   |

---

## RefreshToken

| Campo        | Tipo                 | Notas                   |
| ------------ | -------------------- | ----------------------- |
| `token_id`   | UUID PK              | JTI del JWT             |
| `user_id`    | UUID FK → User       |                         |
| `token_hash` | varchar              | SHA-256 del token crudo |
| `expires_at` | timestamptz          |                         |
| `revoked_at` | timestamptz nullable | Null = activo           |

---

## Sport

| Campo  | Tipo           | Notas                            |
| ------ | -------------- | -------------------------------- |
| `id`   | UUID PK        |                                  |
| `key`  | varchar unique | Ej. `formula1`, `basketball_nba` |
| `name` | varchar        |                                  |

---

## Competition

| Campo      | Tipo            | Notas                              |
| ---------- | --------------- | ---------------------------------- |
| `id`       | UUID PK         |                                    |
| `sport_id` | UUID FK → Sport |                                    |
| `name`     | varchar         |                                    |
| `kind`     | enum            | `league` / `tournament` / `series` |
| `region`   | varchar         |                                    |
| `country`  | varchar         |                                    |

---

## Season

| Campo            | Tipo                  | Notas |
| ---------------- | --------------------- | ----- |
| `id`             | UUID PK               |       |
| `competition_id` | UUID FK → Competition |       |
| `name`           | varchar               |       |
| `start_date`     | date                  |       |
| `end_date`       | date                  |       |

---

## Venue

| Campo      | Tipo             | Notas                                     |
| ---------- | ---------------- | ----------------------------------------- |
| `id`       | UUID PK          |                                           |
| `sport_id` | UUID FK nullable |                                           |
| `name`     | varchar          |                                           |
| `kind`     | enum             | `stadium` / `circuit` / `arena` / `other` |
| `country`  | varchar          |                                           |
| `city`     | varchar          |                                           |
| `timezone` | varchar          | IANA tz                                   |

---

## Participant

| Campo        | Tipo            | Notas                                        |
| ------------ | --------------- | -------------------------------------------- |
| `id`         | UUID PK         |                                              |
| `sport_id`   | UUID FK → Sport |                                              |
| `kind`       | enum            | `team` / `athlete` / `constructor` / `other` |
| `name`       | varchar         |                                              |
| `short_name` | varchar         |                                              |
| `country`    | varchar         |                                              |

---

## Event

Entidad central. Modela sesiones F1, partidos NBA, encuentros de esports, etc.

| Campo               | Tipo                  | Notas                                                         |
| ------------------- | --------------------- | ------------------------------------------------------------- |
| `id`                | UUID PK               |                                                               |
| `sport_id`          | UUID FK               |                                                               |
| `competition_id`    | UUID FK               |                                                               |
| `season_id`         | UUID FK               |                                                               |
| `venue_id`          | UUID FK               |                                                               |
| `parent_event_id`   | UUID self-FK nullable | Agrupa sesiones bajo un mismo evento padre                    |
| `event_type`        | varchar               | `race`, `qualifying`, `match`, etc.                           |
| `name`              | varchar               |                                                               |
| `stage`             | varchar               |                                                               |
| `status`            | enum                  | `scheduled` / `live` / `finished` / `cancelled` / `postponed` |
| `start_time_utc`    | timestamptz           |                                                               |
| `end_time_utc`      | timestamptz nullable  |                                                               |
| `participants_mode` | enum                  | `none` / `teams` / `field`                                    |
| `external_provider` | varchar               | `openf1`, `balldontlie`, `pandascore`                         |
| `external_id`       | varchar               | ID en el proveedor externo                                    |

---

## EventEntry

| Campo            | Tipo       | Notas                            |
| ---------------- | ---------- | -------------------------------- |
| `event_id`       | UUID PK/FK | Clave compuesta                  |
| `participant_id` | UUID PK/FK | Clave compuesta                  |
| `side`           | enum       | `home` / `away` / `blue` / `red` |
| `display_order`  | int        |                                  |

---

## MediaAsset

| Campo             | Tipo    | Notas                                |
| ----------------- | ------- | ------------------------------------ |
| `id`              | UUID PK |                                      |
| `owner_type`      | varchar | Tipo de entidad propietaria          |
| `owner_id`        | UUID    | ID de la entidad propietaria         |
| `asset_type`      | enum    | `logo` / `icon` / `banner` / `photo` |
| `url`             | text    |                                      |
| `source_provider` | varchar |                                      |

---

## UserSportFollow

| Campo               | Tipo          | Notas                         |
| ------------------- | ------------- | ----------------------------- |
| `id`                | UUID PK       |                               |
| `user_id`           | UUID FK       |                               |
| `sport_id`          | UUID FK       |                               |
| `follow_type`       | enum          | `competition` / `participant` |
| `competition_id`    | UUID nullable |                               |
| `participant_id`    | UUID nullable |                               |
| `event_type_filter` | text[]        | Filtro de tipos de evento     |
| `notify`            | boolean       |                               |

---

## UserSportNotificationChannel

| Campo                       | Tipo       | Notas                            |
| --------------------------- | ---------- | -------------------------------- |
| `user_id`                   | UUID PK    | Clave compuesta                  |
| `sport_id`                  | UUID PK    | Clave compuesta                  |
| `channel`                   | varchar PK | `telegram` / `discord` / `email` |
| `enabled`                   | boolean    |                                  |
| `default_lead_time_minutes` | int        | Antelación por defecto           |

---

## UserFollowNotificationChannel

| Campo                        | Tipo         | Notas                           |
| ---------------------------- | ------------ | ------------------------------- |
| `follow_id`                  | UUID PK      | Clave compuesta                 |
| `channel`                    | varchar PK   | Clave compuesta                 |
| `enabled`                    | boolean      |                                 |
| `override_lead_time_minutes` | int nullable | Sobreescribe el valor del sport |

---

## UserSportSettings

| Campo               | Tipo    | Notas                               |
| ------------------- | ------- | ----------------------------------- |
| `user_id`           | UUID PK | Clave compuesta                     |
| `sport_id`          | UUID PK | Clave compuesta                     |
| `follow_all`        | boolean | Sigue todos los eventos del deporte |
| `event_type_filter` | text[]  |                                     |
| `notify_default`    | boolean |                                     |

---

## UserEventAlert

Registro de cada alerta individual a enviar.

| Campo               | Tipo                 | Notas                                 |
| ------------------- | -------------------- | ------------------------------------- |
| `id`                | UUID PK              |                                       |
| `user_id`           | UUID FK              |                                       |
| `event_id`          | UUID FK              |                                       |
| `channel`           | varchar              | `telegram` / `discord` / `email`      |
| `lead_time_minutes` | int                  |                                       |
| `send_at_utc`       | timestamptz          | `start_time - lead_time`              |
| `idempotency_key`   | varchar unique       | Previene duplicados en re-ejecuciones |
| `status`            | enum                 | Ver [[sistema-alertas\|estados]]      |
| `attempts`          | int                  |                                       |
| `max_attempts`      | int                  | Por defecto 6                         |
| `next_retry_at_utc` | timestamptz nullable |                                       |
| `stream_name`       | varchar              | Stream Redis donde se publicó         |
| `stream_message_id` | varchar              | ID del mensaje Redis                  |
| `worker_id`         | varchar              | Worker que procesó la alerta          |
| `artifact_required` | boolean              |                                       |
| `artifact_id`       | UUID FK nullable     |                                       |

---

## AlertDeliveryAttempt

| Campo        | Tipo    | Notas                                                 |
| ------------ | ------- | ----------------------------------------------------- |
| `id`         | UUID PK |                                                       |
| `alert_id`   | UUID FK |                                                       |
| `attempt_no` | int     |                                                       |
| `channel`    | varchar |                                                       |
| `outcome`    | enum    | `success` / `retryable_failure` / `permanent_failure` |
| `error_code` | varchar |                                                       |
| `latency_ms` | int     |                                                       |

---

## AlertArtifact

Imagen pre-renderizada para adjuntar a alertas.

| Campo                 | Tipo        | Notas                   |
| --------------------- | ----------- | ----------------------- |
| `id`                  | UUID PK     |                         |
| `event_id`            | UUID FK     |                         |
| `artifact_type`       | varchar     | `image`                 |
| `storage_provider`    | varchar     | `cloudinary`            |
| `storage_key`         | varchar     |                         |
| `asset_url`           | text        |                         |
| `render_context_hash` | varchar     | Hash para deduplicación |
| `created_at`          | timestamptz |                         |
| `expires_at`          | timestamptz |                         |

---

## AuditLog

| Campo           | Tipo          | Notas                              |
| --------------- | ------------- | ---------------------------------- |
| `id`            | UUID PK       |                                    |
| `actor_user_id` | UUID nullable |                                    |
| `source`        | varchar       | Sistema o usuario                  |
| `action`        | varchar       | Ej. `USER_CREATED`, `ROLE_CHANGED` |
| `entity_type`   | varchar       |                                    |
| `entity_id`     | varchar       |                                    |
| `detail`        | jsonb         | Payload libre                      |
| `ip_address`    | inet          |                                    |
| `trace_id`      | varchar       | Correlación con logs               |

---

## LoadTestRun

| Campo          | Tipo        | Notas                                          |
| -------------- | ----------- | ---------------------------------------------- |
| `id`           | UUID PK     |                                                |
| `run_uuid`     | UUID unique |                                                |
| `scenario_id`  | varchar     |                                                |
| `container_id` | varchar     | ID del contenedor Docker k6                    |
| `status`       | enum        | `running` / `stopped` / `completed` / `failed` |
| `vus`          | int         | Virtual users                                  |
| `duration`     | int         | Segundos                                       |
| `summary_json` | jsonb       | Resultado final de k6                          |

---

## DiscordGuildConfig

| Campo                          | Tipo       | Notas                   |
| ------------------------------ | ---------- | ----------------------- |
| `guild_id`                     | varchar PK | ID del servidor Discord |
| `default_channel_id`           | varchar    | Canal por defecto       |
| `installed_by_discord_user_id` | varchar    |                         |

---

## DiscordGuildSportChannel

| Campo        | Tipo       | Notas                             |
| ------------ | ---------- | --------------------------------- |
| `guild_id`   | varchar PK | Clave compuesta                   |
| `sport_id`   | UUID PK    | Clave compuesta                   |
| `channel_id` | varchar    | Canal de Discord para ese deporte |

---

## UserDiscordDeliveryPreference

| Campo      | Tipo             | Notas                             |
| ---------- | ---------------- | --------------------------------- |
| `user_id`  | UUID PK/FK       |                                   |
| `mode`     | enum             | `DM` / `GUILD_CHANNEL`            |
| `guild_id` | varchar nullable | Requerido si `mode=GUILD_CHANNEL` |

---

## UserDiscordSportDeliveryOverride

| Campo      | Tipo             | Notas                  |
| ---------- | ---------------- | ---------------------- |
| `user_id`  | UUID PK          | Clave compuesta        |
| `sport_id` | UUID PK          | Clave compuesta        |
| `mode`     | enum             | `DM` / `GUILD_CHANNEL` |
| `guild_id` | varchar nullable |                        |

## Fuentes

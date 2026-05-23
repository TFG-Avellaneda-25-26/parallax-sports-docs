---
title: Modelo de datos
description: Entidades JPA del backend de Parallax Sports con sus campos principales y relaciones.
tags: [backend, base-de-datos, jpa, entidades]
---

# Modelo de datos

<details>
<summary><strong>Schema SQL completo</strong></summary>

```sql
-- ============================================================
-- schema-full-rebuild.sql - Sports Dashboard DB (PostgreSQL)
-- Drops and recreates the full public schema from scratch.
-- ============================================================

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SET search_path TO public;

-- Helper: updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- ============================================================
-- 1) CORE CATALOG
-- ============================================================
CREATE TABLE IF NOT EXISTS sports (
  id bigserial PRIMARY KEY,
  key text NOT NULL UNIQUE,
  name text NOT NULL
);

CREATE TABLE IF NOT EXISTS competitions (
  id bigserial PRIMARY KEY,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  name text NOT NULL,
  kind text NOT NULL CHECK (kind IN ('league', 'tournament', 'series')),
  region text NULL,
  country text NULL
);
CREATE INDEX IF NOT EXISTS competitions_sport_idx ON competitions(sport_id);

CREATE TABLE IF NOT EXISTS seasons (
  id bigserial PRIMARY KEY,
  competition_id bigint NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  name text NOT NULL,
  start_date date NULL,
  end_date date NULL
);
CREATE INDEX IF NOT EXISTS seasons_competition_idx ON seasons(competition_id);

-- ============================================================
-- 2) VENUES
-- ============================================================
CREATE TABLE IF NOT EXISTS venues (
  id bigserial PRIMARY KEY,
  sport_id bigint NULL REFERENCES sports(id) ON DELETE SET NULL,
  name text NOT NULL,
  kind text NOT NULL CHECK (kind IN ('stadium', 'circuit', 'arena', 'other')),
  country text NULL,
  city text NULL,
  timezone text NULL
);
CREATE INDEX IF NOT EXISTS venues_sport_idx ON venues(sport_id);

-- ============================================================
-- 3) PARTICIPANTS
-- ============================================================
CREATE TABLE IF NOT EXISTS participants (
  id bigserial PRIMARY KEY,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('team', 'athlete', 'constructor', 'other')),
  name text NOT NULL,
  short_name text NULL,
  country text NULL
);
CREATE INDEX IF NOT EXISTS participants_sport_idx ON participants(sport_id);

-- ============================================================
-- 4) EVENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
  id bigserial PRIMARY KEY,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  competition_id bigint NULL REFERENCES competitions(id) ON DELETE SET NULL,
  season_id bigint NULL REFERENCES seasons(id) ON DELETE SET NULL,
  venue_id bigint NULL REFERENCES venues(id) ON DELETE SET NULL,
  parent_event_id bigint NULL REFERENCES events(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  name text NOT NULL,
  stage text NULL,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'live', 'finished', 'cancelled', 'postponed')),
  start_time_utc timestamptz NOT NULL,
  end_time_utc timestamptz NULL,
  participants_mode text NOT NULL DEFAULT 'none'
    CHECK (participants_mode IN ('none', 'teams', 'field')),
  external_provider text NULL,
  external_id text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS events_external_dedup_idx
  ON events(external_provider, external_id)
  WHERE external_provider IS NOT NULL AND external_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS events_sport_time_idx ON events(sport_id, start_time_utc);
CREATE INDEX IF NOT EXISTS events_start_time_idx ON events(start_time_utc);
CREATE TRIGGER trg_events_updated_at BEFORE UPDATE ON events
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- 5) EVENT ENTRIES
-- ============================================================
CREATE TABLE IF NOT EXISTS event_entries (
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  participant_id bigint NOT NULL REFERENCES participants(id) ON DELETE CASCADE,
  side text NULL CHECK (side IN ('home', 'away', 'blue', 'red')),
  display_order int NULL,
  PRIMARY KEY (event_id, participant_id)
);

-- ============================================================
-- 6) MEDIA ASSETS
-- ============================================================
CREATE TABLE IF NOT EXISTS media_assets (
  id bigserial PRIMARY KEY,
  owner_type text NOT NULL
    CHECK (owner_type IN ('sport', 'competition', 'participant', 'venue', 'event')),
  owner_id bigint NOT NULL,
  asset_type text NOT NULL CHECK (asset_type IN ('logo', 'icon', 'banner', 'photo')),
  url text NOT NULL,
  content_type text NULL,
  alt_text text NULL,
  source_provider text NULL,
  source_url text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS media_assets_owner_idx
  ON media_assets(owner_type, owner_id, asset_type);

-- ============================================================
-- 7) USERS + AUTH
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id bigserial PRIMARY KEY,
  email text UNIQUE NULL,
  password_hash text NULL,
  display_name text NULL,
  role text NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
  email_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz NULL
);

CREATE TABLE IF NOT EXISTS user_identities (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL,
  provider_subject text NOT NULL,
  provider_username text NULL,
  provider_email text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_subject)
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  ip_address inet NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_settings (
  user_id bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  theme text NOT NULL DEFAULT 'system' CHECK (theme IN ('light', 'dark', 'system')),
  default_view text NOT NULL DEFAULT 'cards' CHECK (default_view IN ('cards', 'table')),
  timezone text NOT NULL DEFAULT 'UTC',
  locale text NOT NULL DEFAULT 'en',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 8) FOLLOWS
-- ============================================================
CREATE TABLE IF NOT EXISTS user_sport_settings (
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  follow_all boolean NOT NULL DEFAULT false,
  event_type_filter text[] NULL,
  notify_default boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, sport_id)
);

CREATE TABLE IF NOT EXISTS user_sport_follows (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  follow_type text NOT NULL CHECK (follow_type IN ('competition', 'participant')),
  competition_id bigint NULL REFERENCES competitions(id) ON DELETE CASCADE,
  participant_id bigint NULL REFERENCES participants(id) ON DELETE CASCADE,
  event_type_filter text[] NULL,
  notify boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 9) ALERT ARTIFACTS
-- ============================================================
CREATE TABLE IF NOT EXISTS alert_artifacts (
  id bigserial PRIMARY KEY,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  artifact_type text NOT NULL CHECK (artifact_type IN ('image')),
  storage_provider text NOT NULL CHECK (storage_provider IN ('cloudinary')),
  storage_key text NULL,
  asset_url text NOT NULL,
  render_context_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NULL,
  UNIQUE (event_id, artifact_type, render_context_hash)
);

-- ============================================================
-- 10) ALERTS
-- ============================================================
CREATE TABLE IF NOT EXISTS user_event_alerts (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  lead_time_minutes int NOT NULL DEFAULT 30,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN (
      'scheduled', 'waiting_artifact', 'queued', 'processing',
      'sent', 'failed_retryable', 'failed_permanent', 'cancelled'
    )),
  idempotency_key text NOT NULL,
  attempts int NOT NULL DEFAULT 0,
  max_attempts int NOT NULL DEFAULT 6,
  next_retry_at_utc timestamptz NULL,
  send_at_utc timestamptz NOT NULL,
  stream_name text NULL,
  stream_message_id text NULL,
  worker_id text NULL,
  last_error text NULL,
  last_error_code text NULL,
  artifact_required boolean NOT NULL DEFAULT false,
  artifact_id bigint NULL REFERENCES alert_artifacts(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS user_event_alerts_idempotency_uniq
  ON user_event_alerts(idempotency_key);
CREATE INDEX IF NOT EXISTS user_event_alerts_due_claim_idx
  ON user_event_alerts(status, COALESCE(next_retry_at_utc, send_at_utc), id)
  WHERE status IN ('scheduled', 'failed_retryable');

-- ============================================================
-- 11) NOTIFICATION CHANNEL PREFS
-- ============================================================
CREATE TABLE IF NOT EXISTS user_sport_notification_channels (
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  enabled boolean NOT NULL DEFAULT true,
  default_lead_time_minutes int NOT NULL DEFAULT 30,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, sport_id, channel)
);

CREATE TABLE IF NOT EXISTS user_follow_notification_channels (
  follow_id bigint NOT NULL REFERENCES user_sport_follows(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  enabled boolean NOT NULL DEFAULT true,
  override_lead_time_minutes int NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follow_id, channel)
);

-- ============================================================
-- 12) ALERT DELIVERY ATTEMPTS
-- ============================================================
CREATE TABLE IF NOT EXISTS alert_delivery_attempts (
  id bigserial PRIMARY KEY,
  alert_id bigint NOT NULL REFERENCES user_event_alerts(id) ON DELETE CASCADE,
  attempt_no int NOT NULL CHECK (attempt_no > 0),
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  worker_id text NULL,
  stream_name text NULL,
  stream_message_id text NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz NULL,
  outcome text NOT NULL CHECK (outcome IN ('success', 'retryable_failure', 'permanent_failure')),
  error_code text NULL,
  error_message text NULL,
  http_status int NULL,
  provider_message_id text NULL,
  latency_ms int NULL
);

-- ============================================================
-- 13) AUDIT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id bigserial PRIMARY KEY,
  actor_user_id bigint NULL REFERENCES users(id) ON DELETE SET NULL,
  source text NULL,
  action text NOT NULL,
  entity_type text NULL,
  entity_id bigint NULL,
  detail jsonb NULL,
  ip_address inet NULL,
  trace_id text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- 14) DISCORD DELIVERY (multi-guild routing)
-- ============================================================
CREATE TABLE IF NOT EXISTS discord_guild_configs (
  guild_id text PRIMARY KEY,
  default_channel_id text NULL,
  installed_by_discord_user_id text NULL,
  installed_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discord_guild_sport_channels (
  guild_id text NOT NULL REFERENCES discord_guild_configs(guild_id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  channel_id text NOT NULL,
  PRIMARY KEY (guild_id, sport_id)
);

CREATE TABLE IF NOT EXISTS user_discord_delivery_prefs (
  user_id bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  mode text NOT NULL CHECK (mode IN ('DM', 'GUILD_CHANNEL')),
  guild_id text NULL REFERENCES discord_guild_configs(guild_id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT guild_required_when_channel CHECK (mode = 'DM' OR guild_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS user_discord_sport_delivery_overrides (
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  mode text NOT NULL CHECK (mode IN ('DM', 'GUILD_CHANNEL')),
  guild_id text NULL REFERENCES discord_guild_configs(guild_id) ON DELETE SET NULL,
  PRIMARY KEY (user_id, sport_id),
  CONSTRAINT guild_required_when_channel CHECK (mode = 'DM' OR guild_id IS NOT NULL)
);

-- ============================================================
-- 15) LOAD TEST RUNS (k6 control plane)
-- ============================================================
CREATE TABLE IF NOT EXISTS load_test_runs (
  id bigserial PRIMARY KEY,
  run_uuid text NOT NULL UNIQUE,
  scenario_id text NOT NULL,
  container_id text NULL,
  started_by_user_id bigint NULL REFERENCES users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'running'
    CHECK (status IN ('running', 'stopped', 'completed', 'failed')),
  exit_code int NULL,
  summary_json jsonb NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz NULL,
  vus int NULL,
  duration text NULL
);
```

</details>

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

-- ============================================================
-- schema-full-rebuild.sql - Sports Dashboard DB (PostgreSQL)
-- Drops and recreates the full public schema from scratch.
-- ============================================================

DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
SET search_path TO public;

-- ------------------------------------------------------------
-- Helper: updated_at trigger function
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ============================================================
-- 1) CORE CATALOG TABLES
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

CREATE INDEX IF NOT EXISTS competitions_sport_idx
  ON competitions(sport_id);

CREATE TABLE IF NOT EXISTS seasons (
  id bigserial PRIMARY KEY,
  competition_id bigint NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  name text NOT NULL,
  start_date date NULL,
  end_date date NULL
);

CREATE INDEX IF NOT EXISTS seasons_competition_idx
  ON seasons(competition_id);

-- ============================================================
-- 2) OPTIONAL LOCATION TABLES (VENUES)
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

CREATE INDEX IF NOT EXISTS venues_sport_idx
  ON venues(sport_id);

-- ============================================================
-- 3) PARTICIPANTS (TEAMS, ATHLETES, ETC.)
-- ============================================================

CREATE TABLE IF NOT EXISTS participants (
  id bigserial PRIMARY KEY,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('team', 'athlete', 'constructor', 'other')),
  name text NOT NULL,
  short_name text NULL,
  country text NULL
);

CREATE INDEX IF NOT EXISTS participants_sport_idx
  ON participants(sport_id);

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

CREATE INDEX IF NOT EXISTS events_sport_time_idx
  ON events(sport_id, start_time_utc);

CREATE INDEX IF NOT EXISTS events_comp_time_idx
  ON events(competition_id, start_time_utc);

CREATE INDEX IF NOT EXISTS events_venue_time_idx
  ON events(venue_id, start_time_utc)
  WHERE venue_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS events_parent_idx
  ON events(parent_event_id)
  WHERE parent_event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS events_start_time_idx
  ON events(start_time_utc);

CREATE UNIQUE INDEX IF NOT EXISTS events_external_dedup_idx
  ON events(external_provider, external_id)
  WHERE external_provider IS NOT NULL AND external_id IS NOT NULL;

CREATE TRIGGER trg_events_updated_at
BEFORE UPDATE ON events
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

CREATE INDEX IF NOT EXISTS event_entries_participant_idx
  ON event_entries(participant_id, event_id);

-- ============================================================
-- 6) MEDIA ASSETS
-- ============================================================

CREATE TABLE IF NOT EXISTS media_assets (
  id bigserial PRIMARY KEY,
  owner_type text NOT NULL
    CHECK (owner_type IN ('sport', 'competition', 'participant', 'venue', 'event')),
  owner_id bigint NOT NULL,
  asset_type text NOT NULL
    CHECK (asset_type IN ('logo', 'icon', 'banner', 'photo')),
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
-- 7) USERS + AUTH (ADMIN BAKED IN)
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id bigserial PRIMARY KEY,
  email text UNIQUE NULL,
  password_hash text NULL,
  display_name text NULL,

  role text NOT NULL DEFAULT 'USER'
    CHECK (role IN ('USER', 'ADMIN')),

  email_verified boolean NOT NULL DEFAULT false,

  created_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz NULL
);

CREATE INDEX IF NOT EXISTS users_role_idx
  ON users(role);

CREATE INDEX IF NOT EXISTS users_unverified_cleanup_idx
  ON users(email_verified, created_at)
  WHERE email_verified = false;

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

CREATE INDEX IF NOT EXISTS user_identities_user_idx
  ON user_identities(user_id);

CREATE INDEX IF NOT EXISTS user_identities_provider_lookup_idx
  ON user_identities(provider, provider_subject);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id text PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  ip_address inet NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refresh_tokens_user_idx
  ON refresh_tokens(user_id);

CREATE INDEX IF NOT EXISTS refresh_tokens_cleanup_idx
  ON refresh_tokens(expires_at)
  WHERE revoked_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS user_settings (
  user_id bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  theme text NOT NULL DEFAULT 'system'
    CHECK (theme IN ('light', 'dark', 'system')),
  default_view text NOT NULL DEFAULT 'cards'
    CHECK (default_view IN ('cards', 'table')),
  timezone text NOT NULL DEFAULT 'UTC',
  locale text NOT NULL DEFAULT 'en',
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_user_settings_updated_at
BEFORE UPDATE ON user_settings
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

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

CREATE TRIGGER trg_user_sport_settings_updated_at
BEFORE UPDATE ON user_sport_settings
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_sport_follows (
  id bigserial PRIMARY KEY,

  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,

  follow_type text NOT NULL
    CHECK (follow_type IN ('competition', 'participant')),

  competition_id bigint NULL REFERENCES competitions(id) ON DELETE CASCADE,
  participant_id bigint NULL REFERENCES participants(id) ON DELETE CASCADE,

  event_type_filter text[] NULL,
  notify boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT user_sport_follows_exactly_one_target
  CHECK (
    (competition_id IS NOT NULL)::int +
    (participant_id IS NOT NULL)::int = 1
  )
);

CREATE INDEX IF NOT EXISTS user_sport_follows_lookup_idx
  ON user_sport_follows(user_id, sport_id, follow_type);

CREATE UNIQUE INDEX IF NOT EXISTS user_sport_follows_comp_uniq
  ON user_sport_follows(user_id, sport_id, competition_id)
  WHERE competition_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS user_sport_follows_part_uniq
  ON user_sport_follows(user_id, sport_id, participant_id)
  WHERE participant_id IS NOT NULL;

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

CREATE INDEX IF NOT EXISTS alert_artifacts_event_idx
  ON alert_artifacts(event_id, artifact_type, created_at DESC);

-- ============================================================
-- 10) ALERTS / NOTIFICATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS user_event_alerts (
  id bigserial PRIMARY KEY,
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_id bigint NOT NULL REFERENCES events(id) ON DELETE CASCADE,

  channel text NOT NULL
    CHECK (channel IN ('telegram', 'discord', 'email')),

  lead_time_minutes int NOT NULL DEFAULT 30,

  status text NOT NULL DEFAULT 'scheduled'
    CHECK (
      status IN (
        'scheduled',
        'waiting_artifact',
        'queued',
        'processing',
        'sent',
        'failed_retryable',
        'failed_permanent',
        'cancelled'
      )
    ),

  idempotency_key text NOT NULL,
  attempts int NOT NULL DEFAULT 0,
  max_attempts int NOT NULL DEFAULT 6,

  next_retry_at_utc timestamptz NULL,
  queued_at_utc timestamptz NULL,
  processing_started_at_utc timestamptz NULL,
  dispatched_at_utc timestamptz NULL,
  sent_at_utc timestamptz NULL,

  stream_name text NULL,
  stream_message_id text NULL,
  provider_message_id text NULL,
  worker_id text NULL,

  last_error text NULL,
  last_error_code text NULL,

  updated_at timestamptz NOT NULL DEFAULT now(),

  artifact_required boolean NOT NULL DEFAULT false,
  artifact_id bigint NULL REFERENCES alert_artifacts(id) ON DELETE SET NULL,

  send_at_utc timestamptz NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS user_event_alerts_idempotency_uniq
  ON user_event_alerts(idempotency_key);

CREATE INDEX IF NOT EXISTS user_event_alerts_due_claim_idx
  ON user_event_alerts (status, COALESCE(next_retry_at_utc, send_at_utc), id)
  WHERE status IN ('scheduled', 'failed_retryable');

CREATE INDEX IF NOT EXISTS user_event_alerts_waiting_artifact_idx
  ON user_event_alerts (channel, status, send_at_utc, id)
  WHERE status = 'waiting_artifact';

CREATE INDEX IF NOT EXISTS user_event_alerts_channel_status_idx
  ON user_event_alerts (channel, status, send_at_utc);

CREATE INDEX IF NOT EXISTS user_event_alerts_terminal_sent_idx
  ON user_event_alerts (status, COALESCE(sent_at_utc, updated_at), id)
  WHERE status IN ('sent', 'failed_permanent', 'cancelled');

CREATE TRIGGER trg_user_event_alerts_updated_at
BEFORE UPDATE ON user_event_alerts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- 11) NOTIFICATION CHANNEL PREFS
-- ============================================================

CREATE TABLE IF NOT EXISTS user_sport_notification_channels (
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  enabled boolean NOT NULL DEFAULT true,
  default_lead_time_minutes int NOT NULL DEFAULT 30 CHECK (default_lead_time_minutes > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, sport_id, channel)
);

CREATE INDEX IF NOT EXISTS usnc_lookup_idx
  ON user_sport_notification_channels(user_id, sport_id, enabled, channel);

CREATE INDEX IF NOT EXISTS usnc_sport_enabled_channel_idx
  ON user_sport_notification_channels(sport_id, enabled, channel);

CREATE TABLE IF NOT EXISTS user_follow_notification_channels (
  follow_id bigint NOT NULL REFERENCES user_sport_follows(id) ON DELETE CASCADE,
  channel text NOT NULL CHECK (channel IN ('telegram', 'discord', 'email')),
  enabled boolean NOT NULL DEFAULT true,
  override_lead_time_minutes int NULL CHECK (override_lead_time_minutes > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (follow_id, channel)
);

CREATE INDEX IF NOT EXISTS ufnc_follow_idx
  ON user_follow_notification_channels(follow_id, enabled, channel);

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
  latency_ms int NULL CHECK (latency_ms IS NULL OR latency_ms >= 0)
);

CREATE INDEX IF NOT EXISTS alert_delivery_attempts_alert_idx
  ON alert_delivery_attempts(alert_id, attempt_no DESC);

CREATE INDEX IF NOT EXISTS alert_delivery_attempts_outcome_idx
  ON alert_delivery_attempts(outcome, started_at DESC);

CREATE INDEX IF NOT EXISTS alert_delivery_attempts_started_at_idx
  ON alert_delivery_attempts(started_at DESC, id);

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

CREATE INDEX IF NOT EXISTS audit_logs_actor_time_idx
  ON audit_logs(actor_user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS audit_logs_entity_time_idx
  ON audit_logs(entity_type, entity_id, created_at DESC);

-- ============================================================
-- 14) DISCORD DELIVERY (multi-guild + per-user routing)
-- ============================================================

CREATE TABLE IF NOT EXISTS discord_guild_configs (
  guild_id text PRIMARY KEY,
  default_channel_id text NULL,
  installed_by_discord_user_id text NULL,
  installed_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_discord_guild_configs_updated_at
BEFORE UPDATE ON discord_guild_configs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS discord_guild_sport_channels (
  guild_id text NOT NULL REFERENCES discord_guild_configs(guild_id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  channel_id text NOT NULL,
  set_by_discord_user_id text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (guild_id, sport_id)
);

CREATE INDEX IF NOT EXISTS discord_guild_sport_channels_sport_idx
  ON discord_guild_sport_channels(sport_id);

CREATE TRIGGER trg_discord_guild_sport_channels_updated_at
BEFORE UPDATE ON discord_guild_sport_channels
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_discord_delivery_prefs (
  user_id bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  mode text NOT NULL
    CHECK (mode IN ('DM', 'GUILD_CHANNEL')),
  guild_id text NULL REFERENCES discord_guild_configs(guild_id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_discord_delivery_prefs_guild_when_channel
  CHECK (mode = 'DM' OR guild_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS user_discord_delivery_prefs_guild_idx
  ON user_discord_delivery_prefs(guild_id)
  WHERE guild_id IS NOT NULL;

CREATE TRIGGER trg_user_discord_delivery_prefs_updated_at
BEFORE UPDATE ON user_discord_delivery_prefs
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS user_discord_sport_delivery_overrides (
  user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
  mode text NOT NULL
    CHECK (mode IN ('DM', 'GUILD_CHANNEL')),
  guild_id text NULL REFERENCES discord_guild_configs(guild_id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, sport_id),
  CONSTRAINT user_discord_sport_delivery_overrides_guild_when_channel
  CHECK (mode = 'DM' OR guild_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS user_discord_sport_delivery_overrides_sport_idx
  ON user_discord_sport_delivery_overrides(sport_id);

CREATE INDEX IF NOT EXISTS user_discord_sport_delivery_overrides_guild_idx
  ON user_discord_sport_delivery_overrides(guild_id)
  WHERE guild_id IS NOT NULL;

CREATE TRIGGER trg_user_discord_sport_delivery_overrides_updated_at
BEFORE UPDATE ON user_discord_sport_delivery_overrides
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

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

CREATE INDEX IF NOT EXISTS load_test_runs_status_idx
  ON load_test_runs(status, started_at DESC);

CREATE INDEX IF NOT EXISTS load_test_runs_started_at_idx
  ON load_test_runs(started_at DESC);

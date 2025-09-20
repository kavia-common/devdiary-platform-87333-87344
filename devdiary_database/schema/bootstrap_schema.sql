-- DevDiary PostgreSQL Schema Bootstrap
-- This file mirrors the SQL applied via tooling to provision the database.
-- Note: Runtime scripts (startup.sh) prepare DB/user/permissions. Apply this file after DB is up.

-- Schema and extensions
CREATE SCHEMA IF NOT EXISTS devdiary AUTHORIZATION appuser;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

SET search_path TO devdiary, public;

-- Users
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email CITEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  auth_provider TEXT NOT NULL DEFAULT 'local',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

-- User settings
CREATE TABLE IF NOT EXISTS user_settings (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  timezone TEXT NOT NULL DEFAULT 'UTC',
  locale TEXT NOT NULL DEFAULT 'en',
  working_days SMALLINT[] NOT NULL DEFAULT '{1,2,3,4,5}',
  standup_time TIME,
  notification_preferences JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Visibility enum for logs
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'log_visibility') THEN
    CREATE TYPE log_visibility AS ENUM ('private','team','public');
  END IF;
END
$$;

-- Logs (daily raw entries)
CREATE TABLE IF NOT EXISTS logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  raw_text TEXT NOT NULL,
  visibility log_visibility NOT NULL DEFAULT 'private',
  mood TEXT,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, entry_date)
);
CREATE INDEX IF NOT EXISTS idx_logs_user_date ON logs(user_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_logs_tags ON logs USING GIN (tags);

-- Structured log entries
CREATE TABLE IF NOT EXISTS log_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  log_id UUID NOT NULL REFERENCES logs(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT,
  content TEXT,
  project TEXT,
  repo TEXT,
  issue_key TEXT,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER GENERATED ALWAYS AS (
    CASE
      WHEN started_at IS NOT NULL AND ended_at IS NOT NULL
      THEN (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60)::int
      ELSE NULL
    END
  ) STORED,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  position SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_log_entries_log ON log_entries(log_id);
CREATE INDEX IF NOT EXISTS idx_log_entries_type ON log_entries(type);

-- Integrations catalog and user mappings
CREATE TABLE IF NOT EXISTS integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  provider TEXT NOT NULL,
  UNIQUE(name, provider)
);

CREATE TABLE IF NOT EXISTS user_integrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  integration_id UUID NOT NULL REFERENCES integrations(id) ON DELETE CASCADE,
  external_user_id TEXT,
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ,
  scopes TEXT[],
  settings JSONB NOT NULL DEFAULT '{}'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, integration_id)
);
CREATE INDEX IF NOT EXISTS idx_user_integrations_user ON user_integrations(user_id);

-- Passive activity feed (historical events)
CREATE TABLE IF NOT EXISTS activity_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source TEXT NOT NULL,
  event_type TEXT NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  dedupe_key TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, source, dedupe_key)
);
CREATE INDEX IF NOT EXISTS idx_activity_user_time ON activity_events(user_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_activity_event_type ON activity_events(event_type);

-- Daily analytics rollups
CREATE TABLE IF NOT EXISTS analytics_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  commits_count INTEGER NOT NULL DEFAULT 0,
  issues_closed INTEGER NOT NULL DEFAULT 0,
  time_coding_minutes INTEGER NOT NULL DEFAULT 0,
  meetings_minutes INTEGER NOT NULL DEFAULT 0,
  sentiment_avg NUMERIC(4,2),
  tags_top TEXT[],
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, metric_date)
);
CREATE INDEX IF NOT EXISTS idx_analytics_user_date ON analytics_daily(user_id, metric_date);

-- Generated summaries (e.g., stand-ups)
CREATE TABLE IF NOT EXISTS summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  type TEXT NOT NULL DEFAULT 'standup',
  summary TEXT NOT NULL,
  model TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, entry_date, type)
);

-- API keys for programmatic access
CREATE TABLE IF NOT EXISTS api_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  description TEXT,
  token_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_used_at TIMESTAMPTZ,
  UNIQUE(user_id, token_hash)
);

-- Trigger function to maintain updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $BODY$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$BODY$ LANGUAGE plpgsql;

-- Triggers on tables with updated_at
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'users_set_updated_at'
  ) THEN
    CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON users
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'user_settings_set_updated_at'
  ) THEN
    CREATE TRIGGER user_settings_set_updated_at BEFORE UPDATE ON user_settings
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'logs_set_updated_at'
  ) THEN
    CREATE TRIGGER logs_set_updated_at BEFORE UPDATE ON logs
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'user_integrations_set_updated_at'
  ) THEN
    CREATE TRIGGER user_integrations_set_updated_at BEFORE UPDATE ON user_integrations
      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END
$$;

-- Helpful default search path for sessions
ALTER ROLE appuser IN DATABASE myapp SET search_path = devdiary, public;

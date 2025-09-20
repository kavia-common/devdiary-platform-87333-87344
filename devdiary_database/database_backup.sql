--
-- PostgreSQL database dump
--

\restrict xbhiubUdqgdILt1xGCpAW5CwD5iaPloj9lv3faVr2xyesxNVjfmSPAfnjSCR7qS

-- Dumped from database version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.10 (Ubuntu 16.10-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS myapp;
--
-- Name: myapp; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE myapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE myapp OWNER TO postgres;

\unrestrict xbhiubUdqgdILt1xGCpAW5CwD5iaPloj9lv3faVr2xyesxNVjfmSPAfnjSCR7qS
\connect myapp
\restrict xbhiubUdqgdILt1xGCpAW5CwD5iaPloj9lv3faVr2xyesxNVjfmSPAfnjSCR7qS

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: devdiary; Type: SCHEMA; Schema: -; Owner: appuser
--

CREATE SCHEMA devdiary;


ALTER SCHEMA devdiary OWNER TO appuser;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: log_visibility; Type: TYPE; Schema: devdiary; Owner: appuser
--

CREATE TYPE devdiary.log_visibility AS ENUM (
    'private',
    'team',
    'public'
);


ALTER TYPE devdiary.log_visibility OWNER TO appuser;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: devdiary; Owner: appuser
--

CREATE FUNCTION devdiary.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION devdiary.set_updated_at() OWNER TO appuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_events; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.activity_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    source text NOT NULL,
    event_type text NOT NULL,
    occurred_at timestamp with time zone NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    dedupe_key text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.activity_events OWNER TO appuser;

--
-- Name: analytics_daily; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.analytics_daily (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    metric_date date NOT NULL,
    commits_count integer DEFAULT 0 NOT NULL,
    issues_closed integer DEFAULT 0 NOT NULL,
    time_coding_minutes integer DEFAULT 0 NOT NULL,
    meetings_minutes integer DEFAULT 0 NOT NULL,
    sentiment_avg numeric(4,2),
    tags_top text[],
    generated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.analytics_daily OWNER TO appuser;

--
-- Name: api_keys; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.api_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    description text,
    token_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


ALTER TABLE devdiary.api_keys OWNER TO appuser;

--
-- Name: integrations; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.integrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    provider text NOT NULL
);


ALTER TABLE devdiary.integrations OWNER TO appuser;

--
-- Name: log_entries; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.log_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    log_id uuid NOT NULL,
    type text NOT NULL,
    title text,
    content text,
    project text,
    repo text,
    issue_key text,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    duration_minutes integer GENERATED ALWAYS AS (
CASE
    WHEN ((started_at IS NOT NULL) AND (ended_at IS NOT NULL)) THEN (EXTRACT(epoch FROM (ended_at - started_at)) / (60)::numeric)
    ELSE NULL::numeric
END) STORED,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    "position" smallint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.log_entries OWNER TO appuser;

--
-- Name: logs; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    entry_date date NOT NULL,
    raw_text text NOT NULL,
    visibility devdiary.log_visibility DEFAULT 'private'::devdiary.log_visibility NOT NULL,
    mood text,
    tags text[] DEFAULT '{}'::text[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.logs OWNER TO appuser;

--
-- Name: summaries; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.summaries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    entry_date date NOT NULL,
    type text DEFAULT 'standup'::text NOT NULL,
    summary text NOT NULL,
    model text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.summaries OWNER TO appuser;

--
-- Name: user_integrations; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.user_integrations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    integration_id uuid NOT NULL,
    external_user_id text,
    access_token text,
    refresh_token text,
    expires_at timestamp with time zone,
    scopes text[],
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.user_integrations OWNER TO appuser;

--
-- Name: user_settings; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.user_settings (
    user_id uuid NOT NULL,
    timezone text DEFAULT 'UTC'::text NOT NULL,
    locale text DEFAULT 'en'::text NOT NULL,
    working_days smallint[] DEFAULT '{1,2,3,4,5}'::smallint[] NOT NULL,
    standup_time time without time zone,
    notification_preferences jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE devdiary.user_settings OWNER TO appuser;

--
-- Name: users; Type: TABLE; Schema: devdiary; Owner: appuser
--

CREATE TABLE devdiary.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext NOT NULL,
    display_name text NOT NULL,
    auth_provider text DEFAULT 'local'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_login_at timestamp with time zone
);


ALTER TABLE devdiary.users OWNER TO appuser;

--
-- Data for Name: activity_events; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.activity_events (id, user_id, source, event_type, occurred_at, payload, dedupe_key, created_at) FROM stdin;
\.


--
-- Data for Name: analytics_daily; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.analytics_daily (id, user_id, metric_date, commits_count, issues_closed, time_coding_minutes, meetings_minutes, sentiment_avg, tags_top, generated_at) FROM stdin;
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.api_keys (id, user_id, description, token_hash, created_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: integrations; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.integrations (id, name, provider) FROM stdin;
\.


--
-- Data for Name: log_entries; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.log_entries (id, log_id, type, title, content, project, repo, issue_key, started_at, ended_at, metadata, "position", created_at) FROM stdin;
\.


--
-- Data for Name: logs; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.logs (id, user_id, entry_date, raw_text, visibility, mood, tags, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: summaries; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.summaries (id, user_id, entry_date, type, summary, model, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: user_integrations; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.user_integrations (id, user_id, integration_id, external_user_id, access_token, refresh_token, expires_at, scopes, settings, enabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_settings; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.user_settings (user_id, timezone, locale, working_days, standup_time, notification_preferences, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: devdiary; Owner: appuser
--

COPY devdiary.users (id, email, display_name, auth_provider, created_at, updated_at, last_login_at) FROM stdin;
\.


--
-- Name: activity_events activity_events_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.activity_events
    ADD CONSTRAINT activity_events_pkey PRIMARY KEY (id);


--
-- Name: activity_events activity_events_user_id_source_dedupe_key_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.activity_events
    ADD CONSTRAINT activity_events_user_id_source_dedupe_key_key UNIQUE (user_id, source, dedupe_key);


--
-- Name: analytics_daily analytics_daily_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.analytics_daily
    ADD CONSTRAINT analytics_daily_pkey PRIMARY KEY (id);


--
-- Name: analytics_daily analytics_daily_user_id_metric_date_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.analytics_daily
    ADD CONSTRAINT analytics_daily_user_id_metric_date_key UNIQUE (user_id, metric_date);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_user_id_token_hash_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.api_keys
    ADD CONSTRAINT api_keys_user_id_token_hash_key UNIQUE (user_id, token_hash);


--
-- Name: integrations integrations_name_provider_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.integrations
    ADD CONSTRAINT integrations_name_provider_key UNIQUE (name, provider);


--
-- Name: integrations integrations_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.integrations
    ADD CONSTRAINT integrations_pkey PRIMARY KEY (id);


--
-- Name: log_entries log_entries_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.log_entries
    ADD CONSTRAINT log_entries_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: logs logs_user_id_entry_date_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.logs
    ADD CONSTRAINT logs_user_id_entry_date_key UNIQUE (user_id, entry_date);


--
-- Name: summaries summaries_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.summaries
    ADD CONSTRAINT summaries_pkey PRIMARY KEY (id);


--
-- Name: summaries summaries_user_id_entry_date_type_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.summaries
    ADD CONSTRAINT summaries_user_id_entry_date_type_key UNIQUE (user_id, entry_date, type);


--
-- Name: user_integrations user_integrations_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_integrations
    ADD CONSTRAINT user_integrations_pkey PRIMARY KEY (id);


--
-- Name: user_integrations user_integrations_user_id_integration_id_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_integrations
    ADD CONSTRAINT user_integrations_user_id_integration_id_key UNIQUE (user_id, integration_id);


--
-- Name: user_settings user_settings_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_settings
    ADD CONSTRAINT user_settings_pkey PRIMARY KEY (user_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_activity_event_type; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_activity_event_type ON devdiary.activity_events USING btree (event_type);


--
-- Name: idx_activity_user_time; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_activity_user_time ON devdiary.activity_events USING btree (user_id, occurred_at);


--
-- Name: idx_analytics_user_date; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_analytics_user_date ON devdiary.analytics_daily USING btree (user_id, metric_date);


--
-- Name: idx_log_entries_log; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_log_entries_log ON devdiary.log_entries USING btree (log_id);


--
-- Name: idx_log_entries_type; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_log_entries_type ON devdiary.log_entries USING btree (type);


--
-- Name: idx_logs_tags; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_logs_tags ON devdiary.logs USING gin (tags);


--
-- Name: idx_logs_user_date; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_logs_user_date ON devdiary.logs USING btree (user_id, entry_date);


--
-- Name: idx_user_integrations_user; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_user_integrations_user ON devdiary.user_integrations USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: devdiary; Owner: appuser
--

CREATE INDEX idx_users_email ON devdiary.users USING btree (email);


--
-- Name: logs logs_set_updated_at; Type: TRIGGER; Schema: devdiary; Owner: appuser
--

CREATE TRIGGER logs_set_updated_at BEFORE UPDATE ON devdiary.logs FOR EACH ROW EXECUTE FUNCTION devdiary.set_updated_at();


--
-- Name: user_integrations user_integrations_set_updated_at; Type: TRIGGER; Schema: devdiary; Owner: appuser
--

CREATE TRIGGER user_integrations_set_updated_at BEFORE UPDATE ON devdiary.user_integrations FOR EACH ROW EXECUTE FUNCTION devdiary.set_updated_at();


--
-- Name: user_settings user_settings_set_updated_at; Type: TRIGGER; Schema: devdiary; Owner: appuser
--

CREATE TRIGGER user_settings_set_updated_at BEFORE UPDATE ON devdiary.user_settings FOR EACH ROW EXECUTE FUNCTION devdiary.set_updated_at();


--
-- Name: users users_set_updated_at; Type: TRIGGER; Schema: devdiary; Owner: appuser
--

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON devdiary.users FOR EACH ROW EXECUTE FUNCTION devdiary.set_updated_at();


--
-- Name: activity_events activity_events_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.activity_events
    ADD CONSTRAINT activity_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: analytics_daily analytics_daily_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.analytics_daily
    ADD CONSTRAINT analytics_daily_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: log_entries log_entries_log_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.log_entries
    ADD CONSTRAINT log_entries_log_id_fkey FOREIGN KEY (log_id) REFERENCES devdiary.logs(id) ON DELETE CASCADE;


--
-- Name: logs logs_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.logs
    ADD CONSTRAINT logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: summaries summaries_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.summaries
    ADD CONSTRAINT summaries_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: user_integrations user_integrations_integration_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_integrations
    ADD CONSTRAINT user_integrations_integration_id_fkey FOREIGN KEY (integration_id) REFERENCES devdiary.integrations(id) ON DELETE CASCADE;


--
-- Name: user_integrations user_integrations_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_integrations
    ADD CONSTRAINT user_integrations_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: user_settings user_settings_user_id_fkey; Type: FK CONSTRAINT; Schema: devdiary; Owner: appuser
--

ALTER TABLE ONLY devdiary.user_settings
    ADD CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES devdiary.users(id) ON DELETE CASCADE;


--
-- Name: DATABASE myapp; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE myapp TO appuser;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO appuser;


--
-- Name: FUNCTION citextin(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextin(cstring) TO appuser;


--
-- Name: FUNCTION citextout(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextout(public.citext) TO appuser;


--
-- Name: FUNCTION citextrecv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextrecv(internal) TO appuser;


--
-- Name: FUNCTION citextsend(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextsend(public.citext) TO appuser;


--
-- Name: TYPE citext; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.citext TO appuser;


--
-- Name: FUNCTION citext(boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(boolean) TO appuser;


--
-- Name: FUNCTION citext(character); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(character) TO appuser;


--
-- Name: FUNCTION citext(inet); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(inet) TO appuser;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO appuser;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO appuser;


--
-- Name: FUNCTION citext_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_eq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_eq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash(public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash_extended(public.citext, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash_extended(public.citext, bigint) TO appuser;


--
-- Name: FUNCTION citext_larger(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_larger(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_smaller(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_smaller(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO appuser;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO appuser;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO appuser;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO appuser;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO appuser;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO appuser;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO appuser;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO appuser;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO appuser;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION replace(public.citext, public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.replace(public.citext, public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION split_part(public.citext, public.citext, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.split_part(public.citext, public.citext, integer) TO appuser;


--
-- Name: FUNCTION strpos(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strpos(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION translate(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.translate(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION max(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.max(public.citext) TO appuser;


--
-- Name: FUNCTION min(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.min(public.citext) TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TYPES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO appuser;


--
-- PostgreSQL database dump complete
--

\unrestrict xbhiubUdqgdILt1xGCpAW5CwD5iaPloj9lv3faVr2xyesxNVjfmSPAfnjSCR7qS


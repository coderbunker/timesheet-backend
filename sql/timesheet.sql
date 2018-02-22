--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: dw; Type: SCHEMA; Schema: -; Owner: rngadam
--

CREATE SCHEMA dw;


ALTER SCHEMA dw OWNER TO rngadam;

--
-- Name: incoming; Type: SCHEMA; Schema: -; Owner: rngadam
--

CREATE SCHEMA incoming;


ALTER SCHEMA incoming OWNER TO rngadam;

--
-- Name: postgraphql_watch; Type: SCHEMA; Schema: -; Owner: rngadam
--

CREATE SCHEMA postgraphql_watch;


ALTER SCHEMA postgraphql_watch OWNER TO rngadam;

--
-- Name: timedata; Type: SCHEMA; Schema: -; Owner: rngadam
--

CREATE SCHEMA timedata;


ALTER SCHEMA timedata OWNER TO rngadam;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = postgraphql_watch, pg_catalog;

--
-- Name: notify_watchers(); Type: FUNCTION; Schema: postgraphql_watch; Owner: rngadam
--

CREATE FUNCTION notify_watchers() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$ begin perform pg_notify( 'postgraphql_watch', (select array_to_json(array_agg(x)) from (select schema_name as schema, command_tag as command from pg_event_trigger_ddl_commands()) as x)::text ); end; $$;


ALTER FUNCTION postgraphql_watch.notify_watchers() OWNER TO rngadam;

SET search_path = timedata, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: entries; Type: TABLE; Schema: timedata; Owner: rngadam
--

CREATE TABLE entries (
    entry_date text,
    start text,
    stop text,
    resource text,
    project_name text
);


ALTER TABLE entries OWNER TO rngadam;

SET search_path = dw, pg_catalog;

--
-- Name: entries; Type: VIEW; Schema: dw; Owner: rngadam
--

CREATE VIEW entries AS
 SELECT public.uuid_generate_v1() AS uuid,
    ((entries.entry_date)::timestamp without time zone + ((entries.start)::timestamp without time zone - '1899-12-31 00:00:00'::timestamp without time zone)) AS start,
    ((entries.entry_date)::timestamp without time zone + ((entries.stop)::timestamp without time zone - '1899-12-31 00:00:00'::timestamp without time zone)) AS stop,
    entries.resource AS person_name,
    entries.project_name
   FROM timedata.entries;


ALTER TABLE entries OWNER TO rngadam;

--
-- Name: projects; Type: VIEW; Schema: dw; Owner: rngadam
--

CREATE VIEW projects AS
 SELECT DISTINCT entries.project_name
   FROM timedata.entries;


ALTER TABLE projects OWNER TO rngadam;

SET search_path = incoming, pg_catalog;

--
-- Name: data; Type: TABLE; Schema: incoming; Owner: rngadam
--

CREATE TABLE data (
    data json,
    ts timestamp with time zone DEFAULT now(),
    id text NOT NULL
);


ALTER TABLE data OWNER TO rngadam;

--
-- Name: data data_pkey; Type: CONSTRAINT; Schema: incoming; Owner: rngadam
--

ALTER TABLE ONLY data
    ADD CONSTRAINT data_pkey PRIMARY KEY (id);


--
-- Name: postgraphql_watch; Type: EVENT TRIGGER; Schema: -; Owner: rngadam
--

CREATE EVENT TRIGGER postgraphql_watch ON ddl_command_end
         WHEN TAG IN ('ALTER DOMAIN', 'ALTER FOREIGN TABLE', 'ALTER FUNCTION', 'ALTER SCHEMA', 'ALTER TABLE', 'ALTER TYPE', 'ALTER VIEW', 'COMMENT', 'CREATE DOMAIN', 'CREATE FOREIGN TABLE', 'CREATE FUNCTION', 'CREATE SCHEMA', 'CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW', 'DROP DOMAIN', 'DROP FOREIGN TABLE', 'DROP FUNCTION', 'DROP SCHEMA', 'DROP TABLE', 'DROP VIEW', 'GRANT', 'REVOKE', 'SELECT INTO')
   EXECUTE PROCEDURE postgraphql_watch.notify_watchers();


--
-- Name: incoming; Type: ACL; Schema: -; Owner: rngadam
--

GRANT ALL ON SCHEMA incoming TO postgraphql;


--
-- Name: data; Type: ACL; Schema: incoming; Owner: rngadam
--

GRANT ALL ON TABLE data TO PUBLIC;


--
-- PostgreSQL database dump complete
--


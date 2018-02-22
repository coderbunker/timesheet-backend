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
-- Name: dw; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA dw;


--
-- Name: incoming; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA incoming;


--
-- Name: timedata; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA timedata;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = timedata, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: entries; Type: TABLE; Schema: timedata; Owner: -
--

CREATE TABLE entries (
    entry_date text,
    start text,
    stop text,
    resource text,
    project_name text
);


SET search_path = dw, pg_catalog;

--
-- Name: entries; Type: VIEW; Schema: dw; Owner: -
--

CREATE VIEW entries AS
 SELECT public.uuid_generate_v1() AS uuid,
    ((entries.entry_date)::timestamp without time zone + ((entries.start)::timestamp without time zone - '1899-12-31 00:00:00'::timestamp without time zone)) AS start,
    ((entries.entry_date)::timestamp without time zone + ((entries.stop)::timestamp without time zone - '1899-12-31 00:00:00'::timestamp without time zone)) AS stop,
    entries.resource AS person_name,
    entries.project_name
   FROM timedata.entries;


--
-- Name: projects; Type: VIEW; Schema: dw; Owner: -
--

CREATE VIEW projects AS
 SELECT DISTINCT entries.project_name
   FROM timedata.entries;


SET search_path = incoming, pg_catalog;

--
-- Name: change; Type: TABLE; Schema: incoming; Owner: -
--

CREATE TABLE change (
    data json,
    ts timestamp with time zone DEFAULT now(),
    id text NOT NULL
);


--
-- Name: snapshot; Type: TABLE; Schema: incoming; Owner: -
--

CREATE TABLE snapshot (
    data json,
    ts timestamp with time zone DEFAULT now(),
    id text NOT NULL
);


--
-- Name: snapshot data_pkey; Type: CONSTRAINT; Schema: incoming; Owner: -
--

ALTER TABLE ONLY snapshot
    ADD CONSTRAINT data_pkey PRIMARY KEY (id);


--
-- Name: change incoming_change_data_pkey; Type: CONSTRAINT; Schema: incoming; Owner: -
--

ALTER TABLE ONLY change
    ADD CONSTRAINT incoming_change_data_pkey PRIMARY KEY (id);


--
-- Name: postgraphql_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER postgraphql_watch ON ddl_command_end
         WHEN TAG IN ('ALTER DOMAIN', 'ALTER FOREIGN TABLE', 'ALTER FUNCTION', 'ALTER SCHEMA', 'ALTER TABLE', 'ALTER TYPE', 'ALTER VIEW', 'COMMENT', 'CREATE DOMAIN', 'CREATE FOREIGN TABLE', 'CREATE FUNCTION', 'CREATE SCHEMA', 'CREATE TABLE', 'CREATE TABLE AS', 'CREATE VIEW', 'DROP DOMAIN', 'DROP FOREIGN TABLE', 'DROP FUNCTION', 'DROP SCHEMA', 'DROP TABLE', 'DROP VIEW', 'GRANT', 'REVOKE', 'SELECT INTO')
   EXECUTE PROCEDURE postgraphql_watch.notify_watchers();


--
-- Name: incoming; Type: ACL; Schema: -; Owner: -
--

GRANT ALL ON SCHEMA incoming TO postgraphql;


--
-- Name: change; Type: ACL; Schema: incoming; Owner: -
--

GRANT ALL ON TABLE change TO PUBLIC;


--
-- Name: snapshot; Type: ACL; Schema: incoming; Owner: -
--

GRANT ALL ON TABLE snapshot TO PUBLIC;


--
-- PostgreSQL database dump complete
--


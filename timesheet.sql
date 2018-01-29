-- CREATE DATABASE timesheet;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS timedata;
CREATE SCHEMA IF NOT EXISTS dw;

CREATE OR REPLACE VIEW dw.entries AS
  SELECT
    uuid_generate_v1() AS uuid,
    entry_date::timestamp + (start::timestamp - '1899-12-31T00:00:00.000Z'::timestamp)::interval AS start,
    entry_date::timestamp + (stop::timestamp - '1899-12-31T00:00:00.000Z'::timestamp)::interval AS stop,
    resource as person_name,
    project_name as project_name
  FROM timedata.entries;
  ;

CREATE OR REPLACE VIEW dw.projects AS
  SELECT DISTINCT(project_name) FROM timedata.entries
;

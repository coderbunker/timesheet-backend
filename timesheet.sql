-- CREATE DATABASE timesheet;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS timedata;
CREATE SCHEMA IF NOT EXISTS dw;

CREATE OR REPLACE VIEW dw.entries AS
  SELECT
    uuid_generate_v1() AS uuid,
    start AS start,
    stop AS stop,
    resource as person_name,
    project_name as project_name
  FROM timedata.entries;
  ;

CREATE OR REPLACE VIEW dw.projects AS
  SELECT DISTINCT(project_name) FROM timedata.entries
  ;

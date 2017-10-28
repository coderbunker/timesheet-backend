-- CREATE DATABASE timesheet;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE SCHEMA IF NOT EXISTS timedata;
CREATE SCHEMA IF NOT EXISTS dw;

DROP TABLE IF EXISTS dw.entries;
CREATE TABLE IF NOT EXISTS dw.entries (
  id uuid,
  project_name text,
  start timestamp,
  stop timestamp,
  person_name text
);

INSERT INTO dw.entries VALUES(
  uuid_generate_v1(),
  'test project',
  (select timestamp '2017-10-28 10:00' at time zone 'CST'),
  (select timestamp '2017-10-28 11:00' at time zone 'CST'),
  'Ricky Ng-Adam');

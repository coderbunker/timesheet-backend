BEGIN;

create temporary table temp_json (values text) on commit drop;
\copy temp_json from 'timesheet.json';

CREATE SCHEMA IF NOT EXISTS timedata;
DROP TABLE IF EXISTS timedata.entries CASCADE;


CREATE TABLE timedata.entries AS
  select values->>'date' as entry_date,
         values->>'start' as start,
         values->>'stop' as stop,
         values->>'resource' as resource,
         'project internal'::text as project_name
  from   (
             select json_array_elements(replace(values,'\','\\')::json) as values
             from   temp_json
         ) a;

COMMIT;



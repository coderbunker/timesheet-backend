BEGIN;
create temporary table temp_json (values text) on commit drop;
copy temp_json from '/Users/rngadam/coderbunker/src/timesheet-backend/timesheet.json';

DROP TABLE IF EXISTS timedata.entries;

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

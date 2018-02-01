BEGIN;

create temporary table temp_json (values text) on commit drop;
--\copy temp_json from 'timesheet.json' csv quote e'\x01' delimiter e'\x02';
copy temp_json from '/home/chuck/timesheet/timesheet.json' csv quote e'\x01' delimiter e'\x02';


CREATE SCHEMA IF NOT EXISTS timedata;
DROP TABLE IF EXISTS timedata.entries CASCADE;


CREATE TABLE timedata.entries AS
  select values->>'date' as entry_date,
         values->>'start' as start,
         values->>'stop' as stop,
         values->>'resource' as resource,
	 values->>'hours' as hoursworked,
	 values->>'taskname' as taskname,
	 values->>'activity' as activity,
         'project internal'::text as project_name
  from   (
             select json_array_elements(values::json) as values
             from   temp_json
         ) a
  WHERE values->>'hours' <>'';

CREATE OR REPLACE view timedata.entries_v AS
  SELECT 
	cast(entry_date as date) as entry_date,
	project_name,
	resource,
	taskname,
	activity,
	cast(start as time) as start,
	cast(stop as time) as stop,
	cast( extract(hours from cast(hoursworked as time)) + extract(minutes from cast(hoursworked as time))/60 as float) as hoursworked
  FROM timedata.entries ;
COMMIT;






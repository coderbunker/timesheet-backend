
\c timesheet
BEGIN;


CREATE SCHEMA IF NOT EXISTS timedata;
DROP TABLE IF EXISTS timedata.entries CASCADE;



CREATE TABLE timedata.entries (
	entry_id serial primary key,
	project_name varchar,
	resource varchar,
        activity varchar,
	taskname varchar,
	entry_date date,
	stop time,
	start time,
	hours_worked time
);


CREATE FUNCTION timedata.all_entries(l integer) returns setof timedata.entries as $$ select * from timedata.entries $$ language sql; 

\COPY timedata.entries (project_name, resource, activity, taskname, entry_date, stop, start,hours_worked) FROM 'test.csv' WITH CSV HEADER DELIMITER AS ',';

CREATE OR REPLACE view timedata.entries_v AS
  SELECT 
	project_name,
	resource,
	taskname,
	activity,
	entry_date,
	start,
	stop,
	cast(extract(hours from hours_worked) + extract(minutes from hours_worked)/60 as float) as hours_worked
  FROM timedata.entries ;
COMMIT;



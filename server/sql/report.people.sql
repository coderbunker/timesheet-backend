CREATE SCHEMA report;
DROP VIEW report.summary_person;
CREATE OR REPLACE VIEW report.entry_people AS 
	SELECT 
		entry.*, 
		people.*
	FROM incoming.entry LEFT JOIN incoming.people ON (entry.resource = ANY(people.nicknames))
	WHERE duration IS NOT NULL 
	;

-- https://gist.github.com/ryandotsmith/4602274
CREATE AGGREGATE array_accum (anyarray)
(
    sfunc = array_cat,
    stype = anyarray,
    initcond = '{}'
);  

CREATE VIEW report.duplicate_entries AS
	SELECT 
		email,
		max(resource) AS resource,
		project_id,
		max(name) AS project_name,
		min(start_datetime) AS start_datetime,
		max(stop_datetime) AS stop_datetime,
		max(duration) AS duration,
		COUNT(*) AS duplicate_count
	FROM report.entry_people LEFT JOIN incoming.project ON (entry_people.project_id = project.id)
	GROUP BY email, project_id, start_datetime, stop_datetime
	HAVING COUNT(*) > 1
	ORDER BY resource, project_name;


SELECT * FROM report.entry_people WHERE start_datetime = '2017-07-17T15:00:00+08:00';

CREATE OR REPLACE VIEW report.summary_person AS 
	SELECT 
		round(extract(HOUR FROM sum(duration)))::integer AS total_hours,
		count(DISTINCT project_id) AS project_count,
		array_agg(DISTINCT resource) AS nicknames,
		fullname,
		email,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		extract(days FROM max(stop_datetime) - min(start_datetime)) AS active_days,
		round(avg(EXTRACT(hours FROM duration))::numeric, 1) AS avg_entry_hours
	FROM report.entry_people
	GROUP BY email, fullname
	ORDER BY total_hours DESC
;
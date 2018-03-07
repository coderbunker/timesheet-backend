CREATE SCHEMA report;
DROP VIEW report.summary_person;
DROP VIEW report.entry_people_project;

CREATE OR REPLACE VIEW report.entry_people_project AS 
	SELECT 
		entry.*,
		people.*,
		project.*,
		project_rate,
		currency
	FROM incoming.entry 
		LEFT JOIN incoming.people ON (incoming.search_profile(entry.resource) = people.email)
		LEFT JOIN incoming.project ON (entry.project_id = project.id)
		LEFT JOIN incoming.people_project ON (entry.project_id = people_project.project_id AND people.email = people_project.email)
	WHERE duration IS NOT NULL 
	;

SELECT * FROM report.entry_people_project;
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

DROP VIEW report.summary_person;
CREATE OR REPLACE VIEW report.summary_person AS 
	SELECT 
		round(extract(HOUR FROM sum(duration)))::integer AS total_hours,
		count(DISTINCT project_id) AS project_count,
		array_agg(DISTINCT resource) AS nicknames,
		max(fullname) AS fullname,
		email,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		extract(days FROM max(stop_datetime) - min(start_datetime))::int AS active_days,
		round(avg(EXTRACT(hours FROM duration))::numeric, 1) AS avg_entry_hours
	FROM report.entry_people
	GROUP BY email
	ORDER BY total_hours DESC
;

CREATE OR REPLACE FUNCTION compute_gross(text, float, INTERVAL) RETURNS NUMERIC AS
$$
DECLARE 
	project_rate float;
BEGIN
	if($1 = '1F7TYweE11OqGyZZRZYmmMMHLDokhfyPHQMkdZKzV6Qs') THEN
		project_rate = 0;
	ELSE
		project_rate = $2;
	END IF;
	RETURN round((project_rate * (extract(hours FROM $3) + extract(minutes FROM $3) / 60))::numeric, 2);
END 
$$ LANGUAGE plpgsql IMMUTABLE;

DROP VIEW report.gross_people_project;
CREATE OR REPLACE VIEW report.gross_people_project AS 
	SELECT 
		project_id,
		name,
		email,
		sum(duration) AS total_time,
		project_rate,
		currency,
		compute_gross(project_id, project_rate, sum(duration)) AS gross
	FROM report.entry_people_project
	WHERE 
		extract(MONTH FROM start_datetime) = '02' AND 
		extract(year FROM start_datetime) = '2018'
	GROUP BY project_id, email, name, project_rate, currency
	ORDER BY total_time DESC
	;

CREATE OR REPLACE VIEW report.gross_people AS 
	SELECT
		email,
		array_agg(name),
		sum(gross) AS gross_overall
	FROM report.gross_people_project
	GROUP BY email
	;

SELECT * FROM report.gross_people ORDER BY gross_overall DESC;

DROP VIEW  report.gross_project;
CREATE OR REPLACE VIEW report.gross_project AS 
	SELECT
		project_id,
		max(name) AS project_name,
		array_agg(email) AS participants,
		sum(gross) AS gross_overall
	FROM report.gross_people_project
	GROUP BY project_id
	;
SELECT * FROM report.gross_project ORDER BY gross_overall DESC;


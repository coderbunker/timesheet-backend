CREATE SCHEMA IF NOT EXISTS report;

DROP VIEW IF EXISTS report.entry_people_project CASCADE;
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

-- https://gist.github.com/ryandotsmith/4602274
DROP AGGREGATE IF EXISTS array_accum(anyarray);
CREATE AGGREGATE array_accum (anyarray)
(
    sfunc = array_cat,
    stype = anyarray,
    initcond = '{}'
);  

CREATE OR REPLACE VIEW report.duplicate_entries AS
	SELECT 
		email,
		max(resource) AS resource,
		project_id,
		max(name) AS project_name,
		min(start_datetime) AS start_datetime,
		max(stop_datetime) AS stop_datetime,
		max(duration) AS duration,
		COUNT(*) AS duplicate_count
	FROM report.entry_people_project
	GROUP BY email, project_id, start_datetime, stop_datetime
	HAVING COUNT(*) > 1
	ORDER BY resource, project_name;


DROP VIEW IF EXISTS report.summary_person;
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
	FROM report.entry_people_project
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

DROP VIEW IF EXISTS report.gross_people_project CASCADE;
CREATE OR REPLACE VIEW report.gross_people_project AS 
	SELECT 
		project_id,
		name,
		email,
		sum(duration) AS total_time,
		project_rate,
		currency,
		compute_gross(project_id, project_rate, sum(duration)) AS gross,
		(extract(year FROM start_datetime)*100 + extract(MONTH FROM start_datetime))::text AS billable_month
	FROM report.entry_people_project
	GROUP BY 
		project_id, 
		email, 
		name, 
		project_rate, 
		currency, 
		extract(MONTH FROM start_datetime), 
		extract(year FROM start_datetime)
	ORDER BY total_time DESC
	;

CREATE OR REPLACE VIEW report.gross_people AS 
	SELECT
		email,
		array_agg(name),
		round(sum(gross)) AS gross_overall,
		billable_month
	FROM report.gross_people_project
	GROUP BY email, billable_month
	ORDER BY billable_month
	;

DROP VIEW IF EXISTS report.gross_project;
CREATE OR REPLACE VIEW report.gross_project AS 
	SELECT
		project_id,
		max(name) AS project_name,
		array_agg(email) AS participants,
		round(sum(gross)) AS gross_overall,
		billable_month	
	FROM report.gross_people_project
	GROUP BY project_id, billable_month
	;

DROP VIEW IF EXISTS report.organization CASCADE;
CREATE OR REPLACE VIEW report.organization AS 
	SELECT 
			'Coderbunker Shanghai' AS orgname,
			min(summary_person.first_entry) AS since,
			age(now(), min(summary_person.first_entry))::text AS activity,
			count(DISTINCT summary_person.email) AS people_count,
			(SELECT count(DISTINCT gross_project.project_id) FROM report.gross_project) AS project_count,
			(SELECT count(*) FROM incoming.account WHERE status = 'Ongoing') AS ongoing_project_count,
			(SELECT sum(gross_overall) FROM report.gross_project) AS total_gross,
			sum(total_hours)/168 AS total_eng_months
		FROM report.summary_person
		;

-- SELECT * FROM report.organization;
-- SELECT * FROM report.gross_people WHERE billable_month = '201802' ORDER BY gross_overall DESC;
CREATE SCHEMA report;
DROP VIEW report.summary_person;
CREATE OR REPLACE VIEW report.summary_person AS 
	SELECT 
		round(extract(HOUR FROM sum(duration)))::integer AS total_hours,
		count(DISTINCT entry.project_id) AS project_count,
		array_agg(DISTINCT entry.resource) AS nicknames,
		fullname,
		email,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		extract(days FROM max(stop_datetime) - min(start_datetime)) AS active_days,
		round(avg(EXTRACT(hours FROM duration))::numeric, 1) AS avg_entry_hours
	FROM incoming.entry LEFT JOIN incoming.people ON (entry.resource = people.resource)
	WHERE duration IS NOT NULL 
	GROUP BY people.email, people.fullname
	ORDER BY total_hours DESC
;

SELECT * FROM report.summary_person ORDER BY total_hours desc;

SELECT * FROM incoming.entry LEFT JOIN incoming.people ON (entry.resource = people.resource)
WHERE entry.resource ILIKE '%David%'

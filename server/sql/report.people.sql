CREATE SCHEMA report;
DROP VIEW report.summary_person;
CREATE OR REPLACE VIEW report.summary_person AS 
	SELECT 
		round(extract(HOUR FROM sum(duration)))::integer AS total_hours,
		count(DISTINCT entry.project_id) AS project_count,
		fullname,
		email,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		avg(EXTRACT(hours FROM duration)) AS average_entry_hours
	FROM incoming.entry LEFT JOIN incoming.people ON (entry.resource = people.resource)
	WHERE duration IS NOT NULL 
	GROUP BY people.email, people.fullname
	ORDER BY total_hours DESC
;

SELECT * FROM report.summary_person ORDER BY total_hours desc;

SELECT * FROM incoming.entry LEFT JOIN incoming.people ON (entry.resource = people.resource)
WHERE entry.resource ILIKE '%David%'

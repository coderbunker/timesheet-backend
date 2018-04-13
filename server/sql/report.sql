CREATE SCHEMA IF NOT EXISTS report;

CREATE OR REPLACE VIEW report.organization AS
	WITH person_summary AS (
		SELECT 
			COUNT(distinct(person_id)) AS count 
		FROM model.membership
	), project_summary AS (
		SELECT 
			COUNT(*) AS count
		FROM model.project
	), account_summary AS (
		SELECT count(*) 
			FROM model.account 
			WHERE account.properties->>'status' = 'Ongoing'
	), timesheet_summary AS (
		SELECT 
			min(start_datetime) AS since,
			EXTRACT(hour FROM sum(stop_datetime-start_datetime)) AS total_hours,
			age(now(), min(start_datetime))::text AS activity
		FROM model.timesheet
	)
	SELECT 
		timesheet.organization_name AS orgname,
		timesheet_summary.since,
		timesheet_summary.activity,	≈
		person_summary.count AS people_count,
		project_summary.count AS project_count,
		account_summary.count AS ongoing_project_count,
		timesheet_summary.total_hours::integer AS total_hours,
		((timesheet_summary.total_hours)/168)::integer AS total_eng_months
	FROM 
		model.timesheet, 
		person_summary, 
		project_summary, 
		account_summary, 
		timesheet_summary
	LIMIT 1
	;

CREATE OR REPLACE VIEW report.project AS
	SELECT 
		project_id,
		project_name,
		count(*) entry_count,
		sum(stop_datetime-start_datetime) AS total_hours,
		avg(stop_datetime-start_datetime) AS avg_entry,
		max(stop_datetime-start_datetime) AS max_entry,
		count(distinct(email)) AS persons
	FROM model.timesheet
	GROUP BY project_id, project_name
	ORDER BY total_hours DESC
	;
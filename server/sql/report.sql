CREATE SCHEMA IF NOT EXISTS report;

DROP VIEW IF EXISTS report.organization;
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
			extract(HOUR FROM sum(duration)) AS total_hours,
			sum(total) AS total_gross,
			age(now(), min(start_datetime))::text AS activity
		FROM model.timesheet
	)
	SELECT 
		timesheet.organization_name AS orgname,
		timesheet_summary.since,
		timesheet_summary.activity,
		person_summary.count AS people_count,
		project_summary.count AS project_count,
		account_summary.count AS ongoing_project_count,
		timesheet_summary.total_hours AS total_hours,
		((timesheet_summary.total_hours)/168)::integer AS total_eng_months,	
		timesheet_summary.total_gross
	FROM 
		model.timesheet, 
		person_summary,
		project_summary,
		account_summary, 
		timesheet_summary
	LIMIT 1
	;

DROP VIEW IF EXISTS report.project;
CREATE OR REPLACE VIEW report.project AS
	SELECT 
		project_id,
		project_name,
		organization_name,
		count(*) entry_count,
		round(utils.to_numeric_hours(sum(duration)), 2) AS total_entry_hours,
		round(utils.to_numeric_hours(avg(duration)), 2) AS avg_entry_hours,
		round(utils.to_numeric_hours(min(duration)), 2) AS min_entry_hours,
		round(utils.to_numeric_hours(max(duration)), 2) AS max_entry_hours,
		round(sum(total), 2) AS total_gross,
		count(distinct(email)) AS persons
	FROM model.timesheet
	GROUP BY project_id, project_name, organization_name
	ORDER BY total_gross DESC
	;
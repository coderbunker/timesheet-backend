CREATE SCHEMA IF NOT EXISTS report;

DROP VIEW IF EXISTS report.organization CASCADE;
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
			sum(total_discount) AS total_investment,
			age(now(), min(start_datetime))::text AS activity
		FROM model.timesheet
	)
	SELECT 
		timesheet.vendor_name AS orgname,
		timesheet_summary.since,
		timesheet_summary.activity,
		person_summary.count AS people_count,
		project_summary.count AS project_count,
		account_summary.count AS ongoing_project_count,
		timesheet_summary.total_hours AS total_hours,
		((timesheet_summary.total_hours)/168)::integer AS total_eng_months,	
		timesheet_summary.total_gross,
		timesheet_summary.total_investment
	FROM 
		model.timesheet, 
		person_summary,
		project_summary,
		account_summary, 
		timesheet_summary
	LIMIT 1
	;

DROP VIEW IF EXISTS report.project CASCADE;
CREATE OR REPLACE VIEW report.project AS
	SELECT 
		project_id,
		project_name,
		customer_name,
		vendor_name,
		count(*) entry_count,
		round(utils.to_numeric_hours(sum(duration)), 2) AS total_entry_hours,
		round(utils.to_numeric_hours(avg(duration)), 2) AS avg_entry_hours,
		round(utils.to_numeric_hours(min(duration)), 2) AS min_entry_hours,
		round(utils.to_numeric_hours(max(duration)), 2) AS max_entry_hours,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		EXTRACT(DAY FROM (max(stop_datetime)-min(start_datetime))) AS activity_days,
		round(sum(total), 2) AS total_gross,
		round(sum(total_discount), 2) AS total_discount,
		count(distinct(email)) AS person_count
	FROM model.timesheet
	GROUP BY project_id, project_name, customer_name, vendor_name
	ORDER BY total_gross DESC
	;
	
DROP VIEW IF EXISTS report.person CASCADE;
CREATE OR REPLACE VIEW report.person AS
	SELECT 
		person_id,
		person_name,
		count(*) entry_count,
		round(utils.to_numeric_hours(sum(duration)), 2) AS total_entry_hours,
		round(utils.to_numeric_hours(avg(duration)), 2) AS avg_entry_hours,
		round(utils.to_numeric_hours(min(duration)), 2) AS min_entry_hours,
		round(utils.to_numeric_hours(max(duration)), 2) AS max_entry_hours,
		min(start_datetime) AS first_entry,
		max(stop_datetime) AS latest_entry,
		EXTRACT(DAY FROM (max(stop_datetime)-min(start_datetime))) AS activity_days,
		round(sum(total), 2) AS total_gross,
		round(sum(total_discount), 2) AS total_discount,
		count(distinct(project_name)) AS project_count
	FROM model.timesheet
	GROUP BY person_id, person_name
	ORDER BY total_gross DESC
	;
CREATE SCHEMA IF NOT EXISTS report;

CREATE OR REPLACE VIEW report.organization AS
	WITH account_summary AS (
		SELECT vendor_id, count(*) AS active_account
			FROM model.account
			WHERE
				account.properties->>'status' = 'Ongoing'
			GROUP BY account.vendor_id
	)
	SELECT
		*,
		round((total_hours/168)::NUMERIC) AS total_eng_months
	FROM (
		SELECT
			vendor_name AS orgname,
			min(start_datetime) AS since,
			age(now(), min(start_datetime))::text AS activity,
			count(DISTINCT(person_id)) AS people_count,
			count(DISTINCT(project_id)) AS project_count,
			active_account AS ongoing_project_count,
			extract(HOUR FROM sum(duration)) AS total_hours,
			round(sum(total), 2) AS total_gross,
			round(sum(total_discount), 2) AS total_investment
		FROM model.timesheet,
			LATERAL (
				SELECT active_account
					FROM account_summary
					WHERE account_summary.vendor_id = timesheet.vendor_id
			) a
		GROUP BY vendor_name, active_account
	) t;

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
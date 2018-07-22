CREATE OR REPLACE VIEW report.organization AS
	WITH account_summary AS (
		SELECT vendor_id, count(*) AS active_account
			FROM model.account
			WHERE
				account.properties->>'status' = 'Ongoing'
			GROUP BY account.vendor_id
	), active_members AS (
		SELECT count(*) AS count
			FROM report.member_activity
			WHERE last_active_days <= 30
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
			round(sum(total_discount), 2) AS total_investment,
			max(active_members.count) AS active_people_count
		FROM model.timesheet,
			LATERAL (
				SELECT active_account
					FROM account_summary
					WHERE account_summary.vendor_id = timesheet.vendor_id
			) a,
			active_members
		GROUP BY vendor_name, active_account
	) t;
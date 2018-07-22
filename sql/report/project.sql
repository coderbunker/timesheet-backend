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
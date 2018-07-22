CREATE OR REPLACE VIEW report.member_activity AS
	SELECT
		person.*,
		EXTRACT(DAY FROM (now() - max(stop_datetime)))::INTEGER AS last_active_days
	FROM model.timesheet
	INNER JOIN model.person ON person_id = person.id
	GROUP BY person.id
	;

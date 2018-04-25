CREATE OR REPLACE VIEW report.member_activity AS 
	SELECT 
		person.*,
		EXTRACT(DAY FROM (now() - max(stop_datetime)))::INTEGER AS last_active_days
	FROM model.timesheet
	INNER JOIN model.person ON person_id = person.id
	GROUP BY person.id
	;

CREATE OR REPLACE VIEW report.time_tracking_matrix AS
	SELECT 
		account_name, 
		person_name, 
		member_activity.last_active_days
	FROM model.timesheet 
		INNER JOIN report.member_activity ON member_activity.id = timesheet.person_id
		INNER JOIN model.account ON account_id = account.id
	WHERE 
		account.properties->>'status' = 'Ongoing'  
		AND last_active_days <= 90
	GROUP BY account_name, person_name, member_activity.last_active_days
	ORDER BY last_active_days DESC
	;
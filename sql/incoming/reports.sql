CREATE VIEW incoming.report_transfer_per_project AS
	SELECT 
		name AS project_name,
		-- project_id,
		SUM(amount) total, 
		MAX(currency) AS currency,
		count(*) AS transfer_count,
		min(transfer_datetime) AS first_transfer,
		max(transfer_datetime) AS last_transfer,
		round(AVG(amount)) AS average_amount
	FROM model.project 
		LEFT JOIN incoming.transfer ON (properties->>'docid' = project_id)
	WHERE project_id IS NOT NULL
	GROUP BY project_id, name
	ORDER BY total DESC
	;

CREATE VIEW incoming.report_transfer_total_currency AS
	SELECT 
		SUM(amount) total, 
		currency,
		count(*) AS transfer_count,
		count(distinct(project.name)) AS project_count
	FROM model.project 
		LEFT JOIN incoming.transfer ON (properties->>'docid' = project_id)
	WHERE project_id IS NOT NULL
	GROUP BY currency
	ORDER BY total DESC
	;
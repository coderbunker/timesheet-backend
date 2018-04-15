CREATE OR REPLACE VIEW report.warnings AS
	SELECT 
		count(*) AS error_count,
		doc->>'project_id' AS docid,
		project.name,
		array_agg(distinct(error))
	FROM incoming.warnings
		INNER JOIN model.project ON project.properties->>'docid' = doc->>'project_id'
	GROUP BY docid, project.name
	ORDER BY error_count DESC
	;
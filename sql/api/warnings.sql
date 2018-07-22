CREATE OR REPLACE VIEW api.warnings AS
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'api.snapshot' AS table_name,
			'name should be present in doc' AS error
		FROM api.snapshot
		WHERE doc->>'name' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'api.snapshot' AS table_name,
			'timezone should be present in doc' AS error
		FROM api.snapshot
		WHERE doc->>'timezone' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'api.snapshot' AS table_name,
			'apptype should be present in doc' AS error
		FROM api.snapshot
		WHERE doc->>'apptype' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'api.snapshot' AS table_name,
			'category should be present in doc' AS error
		FROM api.snapshot
		WHERE doc->>'category' IS NULL
	)
	;

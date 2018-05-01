
          
CREATE SCHEMA IF NOT EXISTS api;

CREATE OR REPLACE VIEW api.warnings AS
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'incoming.snapshot' AS table_name,
			'name should be present in doc' AS error
		FROM incoming.snapshot
		WHERE doc->>'name' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'incoming.snapshot' AS table_name,
			'timezone should be present in doc' AS error
		FROM incoming.snapshot
		WHERE doc->>'timezone' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'incoming.snapshot' AS table_name,
			'apptype should be present in doc' AS error
		FROM incoming.snapshot
		WHERE doc->>'apptype' IS NULL
	)
	UNION
	(
		SELECT
			id,
			'{}'::jsonb AS doc,
			'incoming.snapshot' AS table_name,
			'category should be present in doc' AS error
		FROM incoming.snapshot
		WHERE doc->>'category' IS NULL
	)
	;

 
CREATE OR REPLACE FUNCTION api.snapshot(text, json)
RETURNS SETOF api.warnings AS
$func$
BEGIN
	INSERT INTO incoming.snapshot(id, doc)
	    VALUES($1, $2)
	    ON CONFLICT(id) DO
	      UPDATE SET doc = EXCLUDED.doc, ts = now() WHERE snapshot.id = EXCLUDED.id;
	RETURN QUERY SELECT * FROM api.warnings WHERE id = $1;
	IF NOT FOUND THEN
		RETURN QUERY SELECT $1::text AS id, doc::jsonb, table_name, error 
			FROM incoming.warnings 
			WHERE doc->>'project_id' = $1;
	END IF;
END;
$func$  LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION api.snapshot_json(text, json)
RETURNS json AS
$func$
	SELECT array_to_json(array(
	    SELECT row_to_json(snapshot.*)
	      FROM api.snapshot($1, $2::json)
	  ));
$func$  LANGUAGE sql;


CREATE OR REPLACE FUNCTION api.snapshot(text, json)
RETURNS SETOF api.warnings AS
$func$
BEGIN
	INSERT INTO api.snapshot(id, doc)
	    VALUES($1, $2)
	    ON CONFLICT(id) DO
	      UPDATE SET doc = EXCLUDED.doc, ts = now() WHERE snapshot.id = EXCLUDED.id;
	RETURN QUERY SELECT * FROM api.warnings WHERE id = $1;
-- TODO: this times out, need better performance out of retrieving warnings
--	IF NOT FOUND THEN
--		RETURN QUERY SELECT $1::text AS id, doc, table_name, error
--			FROM incoming.warnings
--			WHERE doc->>'project_id' = $1;
--	END IF;
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


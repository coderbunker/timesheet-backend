
          
CREATE SCHEMA IF NOT EXISTS api;

CREATE OR REPLACE FUNCTION api.snapshot(text, json)
RETURNS void AS
$func$
BEGIN
	INSERT INTO incoming.snapshot(id, doc)
	    VALUES($1, $2)
	    ON CONFLICT(id) DO
	      UPDATE SET doc = EXCLUDED.doc, ts = now() WHERE snapshot.id = EXCLUDED.id;
END;
$func$  LANGUAGE plpgsql;


--SELECT api.snapshot('fakeid', '{}'::json);
--
--SELECT id, ts FROM incoming.snapshot ORDER BY ts desc;
--
--DELETE FROM incoming.snapshot WHERE id = 'fakeid';
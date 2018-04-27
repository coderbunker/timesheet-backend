-- Usage:
-- SELECT * FROM incoming.update_from_server(
--	<OUTPUT FROM heroku pg:credentials:url>
-- );
CREATE OR REPLACE FUNCTION incoming.update_from_server(connection_url TEXT) RETURNS SETOF incoming.snapshot AS
$update_from_server$
DECLARE
	matches TEXT[];
	host TEXT;
	port TEXT;
	dbname TEXT;
	username TEXT;
	password TEXT;
	current_user TEXT;
BEGIN
	SELECT arr[1], arr[2], arr[3], arr[4], arr[5] INTO STRICT username, password, host, port, dbname FROM (
		SELECT regexp_match( 
			connection_url,
			'postgres:\/\/([a-zA-Z0-9]*):([a-zA-Z0-9]*)@([a-zA-Z0-9\-\.]*):(\d*)\/([a-zA-Z0-9]*)') AS arr
	) t
	;
	
	IF NOT FOUND THEN
		RAISE EXCEPTION 'invalid connection_url: %s', connection_url;
	END IF;

	DROP SERVER IF EXISTS foreign_server CASCADE;
	EXECUTE format($$ CREATE SERVER foreign_server
	        FOREIGN DATA WRAPPER postgres_fdw
	        OPTIONS (host '%s', port '5432', dbname '%s');
	$$, host, dbname);
	
	SELECT current_user INTO current_user;

	EXECUTE format($$ 
		CREATE USER MAPPING IF NOT EXISTS FOR "%s"
	        SERVER foreign_server
	        OPTIONS (user '%s', password '%s');
	$$, current_user, username, password);
	        
	DROP FOREIGN TABLE IF EXISTS foreign_incoming_snapshot;
	CREATE FOREIGN TABLE foreign_incoming_snapshot (
		doc json NOT NULL,
		ts timestamptz NOT NULL DEFAULT now(),
		id text NOT NULL
	)
	SERVER foreign_server
	OPTIONS (schema_name 'incoming', table_name 'snapshot');
	
	RETURN QUERY INSERT INTO incoming.snapshot 
		SELECT remote.* 
			FROM foreign_incoming_snapshot remote
				LEFT JOIN incoming.snapshot ON (snapshot.id = remote.id)
			WHERE snapshot.ts IS NULL OR (snapshot.ts < remote.ts)
	ON CONFLICT(id)
		DO UPDATE SET doc = EXCLUDED.doc, ts = EXCLUDED.ts WHERE snapshot.id = EXCLUDED.id
	RETURNING *
	;
END;
$update_from_server$ LANGUAGE PLPGSQL;

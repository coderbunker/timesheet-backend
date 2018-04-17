-- TODO: almost work but fails on ROLE missing failure
CREATE OR REPLACE FUNCTION update_from_server(connection_url TEXT) RETURNS void AS
$update_from_server$
DECLARE
	host TEXT;
	dbname TEXT;
	username TEXT;
	password TEXT;
BEGIN
	SELECT regexp_match( 
		connection_url,
		'postgres:\/\/([a-zA-Z0-9]*):([a-zA-Z0-9]*)@([a-zA-Z0-9\-\.]*):(\d*)\/([a-zA-Z0-9])')
		INTO username, password, host, dbname;
	
	IF username IS NULL THEN
		RAISE EXCEPTION 'invalid connection_url: %s', connection_url;
	END IF;

	DROP SERVER IF EXISTS foreign_server CASCADE;
	EXECUTE format($$ CREATE SERVER foreign_server
	        FOREIGN DATA WRAPPER postgres_fdw
	        OPTIONS (host '%s', port '5432', dbname '%s');
	$$, host, dbname);
	
	EXECUTE format($$ 
		CREATE USER MAPPING IF NOT EXISTS FOR rngadam
	        SERVER foreign_server
	        OPTIONS (user '%s', password '%s');
	$$, username, password);
	        
	DROP FOREIGN TABLE IF EXISTS foreign_incoming_snapshot;
	CREATE FOREIGN TABLE foreign_incoming_snapshot (
		doc json NOT NULL,
		ts timestamptz NOT NULL DEFAULT now(),
		id text NOT NULL
	)
	SERVER foreign_server
	OPTIONS (schema_name 'incoming', table_name 'snapshot');
	
	INSERT INTO incoming.snapshot(id, doc, ts) 
		SELECT id, doc, ts FROM foreign_incoming_snapshot
	ON CONFLICT(id)
		DO UPDATE SET doc = EXCLUDED.doc, ts = EXCLUDED.ts WHERE snapshot.id = EXCLUDED.id
	;
END;
$update_from_server$ LANGUAGE PLPGSQL;

SELECT * FROM update_from_server(
	-- output from heroku pg:credentials:url
);

CREATE TABLE IF NOT EXISTS incoming.snapshot (
	doc json NOT NULL,
	ts timestamptz NOT NULL DEFAULT now(),
	id text NOT NULL,
	CONSTRAINT data_pkey PRIMARY KEY (id)
)
WITH (
	OIDS=FALSE
) ;

CREATE OR REPLACE VIEW incoming.snapshot_gsuite AS
	SELECT 
		doc->>'name' AS name, 
		doc->>'apptype' AS apptype,
		doc->>'category' AS category,
		ts AS last_update
	FROM incoming.snapshot
	ORDER BY ts DESC;
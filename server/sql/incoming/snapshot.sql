CREATE TABLE IF NOT EXISTS incoming.snapshot (
	id text NOT NULL,
	doc jsonb NOT NULL,
	ts timestamptz NOT NULL DEFAULT now(),
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
	


CREATE TABLE IF NOT EXISTS api.snapshot (
	id text NOT NULL,
	doc jsonb NOT NULL,
	ts timestamptz NOT NULL DEFAULT now(),
	CONSTRAINT data_pkey PRIMARY KEY (id)
)
WITH (
	OIDS=FALSE
) ;

CREATE OR REPLACE VIEW api.snapshot_gsuite AS
	SELECT
		doc->>'name' AS name,
		doc->>'apptype' AS apptype,
		doc->>'category' AS category,
		ts AS last_update
	FROM api.snapshot
	ORDER BY ts DESC;



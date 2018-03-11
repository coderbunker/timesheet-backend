CREATE TABLE IF NOT EXISTS incoming.snapshot (
	doc json NOT NULL,
	ts timestamptz NOT NULL DEFAULT now(),
	id text NOT NULL,
	CONSTRAINT data_pkey PRIMARY KEY (id)
)
WITH (
	OIDS=FALSE
) ;

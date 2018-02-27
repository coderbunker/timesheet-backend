CREATE TABLE incoming.snapshot
(
  data json,
  ts timestamp with time zone DEFAULT now(),
  id text NOT NULL,
  name text,
  timezone text,
  CONSTRAINT data_pkey PRIMARY KEY (id)
);
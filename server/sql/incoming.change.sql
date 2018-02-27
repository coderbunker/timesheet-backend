CREATE TABLE incoming.change
(
  id text NOT NULL,
  data json,
  ts timestamp with time zone DEFAULT now(),
  CONSTRAINT change_data_pkey PRIMARY KEY (id)
);
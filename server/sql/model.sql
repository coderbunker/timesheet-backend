DROP SCHEMA model CASCADE;

CREATE SCHEMA IF NOT EXISTS model;
 
CREATE TABLE IF NOT EXISTS model.person(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	fullname TEXT,
	emails TEXT[],
	nicknames TEXT[],
	github TEXT UNIQUE
);
SELECT audit.add_audit('model.person');

CREATE TABLE IF NOT EXISTS model.account(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT UNIQUE,
	legal_name TEXT UNIQUE
);
	
CREATE TABLE IF NOT EXISTS model.project(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	account_id uuid REFERENCES model.account(id),
	name TEXT UNIQUE 
);

CREATE TABLE IF NOT EXISTS model.iso4217(
	code CHAR(3) PRIMARY KEY
);

DO $$ 
 BEGIN
	INSERT INTO model.iso4217
		SELECT code FROM unnest($c$ {SGD, RMB, USD} $c$::text[]) code
	ON CONFLICT DO NOTHING;
 END;
$$;

CREATE TABLE IF NOT EXISTS model.project_person_rate(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id),
	resource_person_id uuid REFERENCES model.person(id),
	currency CHAR(3) REFERENCES model.iso4217(code),
	hourly_rate NUMERIC
);

CREATE TABLE IF NOT EXISTS model.task(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT
);

CREATE TABLE IF NOT EXISTS model.entry(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_person_rate_id uuid REFERENCES model.project_person_rate(id),
	start_datetime timestamptz,
	stop_datetime timestamptz,
	task_id uuid REFERENCES model.project_person_rate(id),
	activity TEXT,
	reference TEXT,
	CONSTRAINT unique_entry UNIQUE(project_person_rate_id, start_datetime, stop_datetime) 
);

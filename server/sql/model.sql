DROP SCHEMA model CASCADE;

CREATE SCHEMA IF NOT EXISTS model;
 
CREATE TABLE IF NOT EXISTS model.person(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT,
	emails TEXT[],
	nicknames TEXT[],
	github TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS model.organization(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS model.account(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	organization_id uuid REFERENCES model.organization(id) NOT NULL,
	name TEXT UNIQUE,
	legal_name TEXT UNIQUE
);
	
CREATE TABLE IF NOT EXISTS model.project(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	account_id uuid REFERENCES model.account(id) NOT NULL,
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

COMMENT ON TABLE model.iso4217 IS $$
	ISO 4217 is a standard first published by International Organization for Standardization in 1978, 
	which delineates currency designators
$$;
COMMENT ON COLUMN model.iso4217.code IS $$
The first two letters of the code are the two letters of the ISO 3166-1 alpha-2 country codes 
(which are also used as the basis for national top-level domains on the Internet) and the third 
is usually the initial of the currency itself. 
$$;

CREATE TABLE IF NOT EXISTS model.member(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id) NOT NULL,
	person_id uuid REFERENCES model.person(id) NOT NULL,
	currency CHAR(3) REFERENCES model.iso4217(code) NOT NULL,
	hourly_rate NUMERIC
);

CREATE TABLE IF NOT EXISTS model.task(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT
);

CREATE TABLE IF NOT EXISTS model.entry(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	member_id uuid REFERENCES model.member(id),
	start_datetime timestamptz NOT NULL,
	stop_datetime timestamptz NOT NULL,
	task_id uuid REFERENCES model.task(id) NOT NULL,
	activity TEXT,
	reference TEXT,
	CONSTRAINT unique_entry UNIQUE(member_id, start_datetime, stop_datetime) 
);

SELECT audit.add_audit(schemaname, tablename) FROM (
	SELECT schemaname, tablename FROM pg_catalog.pg_tables WHERE schemaname = 'model'
) t;

DROP VIEW IF EXISTS model.timesheet;
CREATE OR REPLACE VIEW model.timesheet AS
	SELECT 
		entry.id AS id,
		organization.name AS organization_name,
		project.name AS project_name,
		account.name AS account_name,
		entry.start_datetime,
		entry.stop_datetime,
		emails[1] AS email,
		task.name AS task_name,
		entry.activity,
		entry.reference
		FROM model.entry 
			INNER JOIN model.member ON entry.member_id = member.id
			INNER JOIN model.person ON member.person_id = person.id
			INNER JOIN model.project ON member.project_id = project.id
			INNER JOIN model.task ON entry.task_id = task.id
			INNER JOIN model.account ON project.account_id = account.id
			INNER JOIN model.organization ON account.organization_id = organization.id
			INNER JOIN model.iso4217 ON member.currency = iso4217.code
	;


CREATE OR REPLACE FUNCTION model.add_entry(
	project_name text,
	email TEXT,
	start_datetime timestamptz, 
	stop_datetime timestamptz, 
	task_name text, 
	activity text, 
	reference text) RETURNS model.timesheet AS
$$
DECLARE
	entry model.entry;
	task model.task;
	project model.project;
	member model.member;
	ts model.timesheet;
BEGIN
	SELECT * INTO task FROM model.task t WHERE t.name = task_name;
	IF task IS NULL THEN
		RAISE EXCEPTION 'Nonexistent task --> %', task_name USING HINT = 'Create task';
	END IF;
	SELECT * INTO project FROM model.project WHERE name = project_name;
	IF project IS NULL THEN
		RAISE EXCEPTION 'Nonexistent project --> %', project_name USING HINT = 'Create project';
	END IF;
	SELECT * INTO member
		FROM model.member m
			INNER JOIN model.person p ON p.id = m.person_id 
		WHERE emails[1] = email AND m.project_id = project.id;
	IF member IS NULL THEN
		RAISE EXCEPTION 'Nonexistent member --> %', email USING HINT = 'Create member with this email';
	END IF;

	INSERT INTO model.entry(
		start_datetime, 
		stop_datetime, 
		activity, 
		reference, 
		task_id, 
		member_id) 
	VALUES (
		start_datetime,
   		stop_datetime,
   		activity,
   		reference,
   		task.id,
   		member.id) 
	RETURNING * INTO entry;

	SELECT * INTO ts 
		FROM model.timesheet t WHERE t.id = entry.id;

	RETURN ts;
END
$$ LANGUAGE plpgsql;

--CREATE RULE timesheet_insert AS ON INSERT TO model.timesheet
--DO INSTEAD
--(
--	SELECT * FROM 
--		model.add_entry(
--			NEW.project_name,
--			NEW.email,
--			NEW.start_datetime,
--			NEW.stop_datetime,
--			NEW.task_name,
--			NEW.activity,
--			NEW.reference
--		);
--);

--CREATE OR REPLACE FUNCTION model.add_entry(member_id uuid, nickname TEXT, start_datetime timestamptz, stop_datetime timestamptz) AS
--$$
--
--$$ LANGUAGE SQL;
SELECT * FROM model.timesheet;
DROP SCHEMA IF EXISTS model CASCADE;
CREATE SCHEMA IF NOT EXISTS model;
 
CREATE EXTENSION IF NOT EXISTS citext;
DROP DOMAIN IF EXISTS email;
CREATE DOMAIN email AS citext
  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );

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

CREATE TABLE IF NOT EXISTS model.organization(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

DO $$ 
 BEGIN
	INSERT INTO model.organization(id, name, properties)
		VALUES 
			('46207d44-ddf3-4ecf-8c01-d88d56d56181', 'Coderbunker Shanghai', '{}'), 
			('dffae778-dd06-46c1-a4ee-b7bfce34f71d', 'Coderbunker Singapore', '{}')
	ON CONFLICT DO NOTHING;
 END;
$$;

CREATE TABLE IF NOT EXISTS model.account(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	organization_id uuid REFERENCES model.organization(id) NOT NULL,
	name TEXT UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

CREATE TABLE IF NOT EXISTS model.person(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT,
	email email UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

-- create unique index person_unique_lower_email_idx on model.person (lower(email));

CREATE TABLE IF NOT EXISTS model.ledger(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	entity_id uuid REFERENCES audit.entity(id) NOT NULL,
	amount NUMERIC NOT NULL,
	recorded TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION model.check_double_entry_balance() RETURNS TRIGGER AS
$$
DECLARE
	balance NUMERIC;
BEGIN
	SELECT SUM(amount) FROM model.ledger INTO balance;
	IF balance <> 0 THEN
		RAISE EXCEPTION 'balance of amount does not match, sum is %', balance;
	END IF;
	RETURN NEW;
END 
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_double_entry_balance_trigger ON model.ledger;
CREATE  TRIGGER check_double_entry_balance_trigger
AFTER INSERT OR UPDATE OR DELETE ON  model.ledger
FOR EACH STATEMENT EXECUTE PROCEDURE model.check_double_entry_balance();

CREATE TABLE IF NOT EXISTS model.project(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	account_id uuid REFERENCES model.account(id) NOT NULL,
	name TEXT UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

CREATE TABLE IF NOT EXISTS model.membership(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id) NOT NULL,
	person_id uuid REFERENCES model.person(id) NOT NULL,
	name TEXT,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_resource_name_per_project UNIQUE (project_id, name)
);


CREATE TABLE IF NOT EXISTS model.rate(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	membership_id uuid REFERENCES model.membership(id) NOT NULL,
	rate NUMERIC NOT NULL, 
	basis TEXT DEFAULT 'hourly' NOT NULL,
	currency CHAR(3) REFERENCES model.iso4217(code) NOT NULL,
	valid TIMESTAMPTZ DEFAULT NOW() NOT NULL,
	CONSTRAINT unique_rate_per_resource_per_project UNIQUE (membership_id, basis)
);

CREATE TABLE IF NOT EXISTS model.task(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id) NOT NULL,
	name TEXT,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_task_name_per_project UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS model.entry(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	membership_id uuid REFERENCES model.membership(id),
	start_datetime timestamptz NOT NULL,
	stop_datetime timestamptz NOT NULL,
	task_id uuid REFERENCES model.task(id) NOT NULL,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_entry UNIQUE(membership_id, start_datetime, stop_datetime) 
);

SELECT audit.add_audit(schemaname, tablename) FROM (
	SELECT schemaname, tablename 
		FROM pg_catalog.pg_tables 
			LEFT JOIN pg_catalog.pg_trigger ON tgname = 'trigger_insert_entity_' || tablename
		WHERE schemaname = 'model' AND tgname IS null
) t;

SELECT * FROM pg_catalog.pg_trigger;

CREATE OR REPLACE VIEW model.timesheet AS
	SELECT 
		entry.id AS id,
		organization.name AS organization_name,
		project.name AS project_name,
		account.name AS account_name,
		entry.start_datetime,
		entry.stop_datetime,
		email,
		task.name AS task_name,
		entry.properties,
		rate.currency,
		rate.rate
		FROM model.entry 
			INNER JOIN model.membership ON entry.membership_id = membership.id
			INNER JOIN model.person ON membership.person_id = person.id
			INNER JOIN model.project ON membership.project_id = project.id
			INNER JOIN model.task ON entry.task_id = task.id
			INNER JOIN model.account ON project.account_id = account.id
			INNER JOIN model.organization ON account.organization_id = organization.id
			INNER JOIN model.rate ON membership.id = rate.membership_id
			INNER JOIN model.iso4217 ON rate.currency = iso4217.code
	;


CREATE OR REPLACE FUNCTION model.add_entry(
	project_name TEXT,
	email_ TEXT,
	start_datetime TIMESTAMPTZ, 
	stop_datetime TIMESTAMPTZ, 
	task_name TEXT, 
	properties JSONB) RETURNS model.timesheet AS
$$
DECLARE
	entry model.entry;
	task model.task;
	project model.project;
	membership model.membership;
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
	SELECT * INTO membership
		FROM model.membership m
			INNER JOIN model.person p ON p.id = m.person_id 
		WHERE p.email = email_ AND m.project_id = project.id;
	IF membership IS NULL THEN
		RAISE EXCEPTION 'Nonexistent membership --> %', email_ USING HINT = 'Create membership with this email';
	END IF;

	INSERT INTO model.entry(
		start_datetime, 
		stop_datetime, 
		task_id, 
		membership_id,
		properties) 
	VALUES (
		start_datetime,
   		stop_datetime,
   		task.id,
   		membership.id,
   		properties) 
	RETURNING * INTO entry;

	SELECT * INTO ts 
		FROM model.timesheet t WHERE t.id = entry.id;

	RETURN ts;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE VIEW model.project_config AS
	SELECT 
		project.id AS id,
		project.name AS project_name,
		max(organization.name) AS organization_name,
		max(account.name) AS account_name,
		array_agg(task.name) AS tasks,
		array_agg(person.name || ' ' || COALESCE(membership.name, '')) AS members
		FROM model.project 
			INNER JOIN model.membership ON membership.project_id = project.id
			INNER JOIN model.person ON membership.person_id = person.id
			INNER JOIN model.task ON task.project_id = project.id
			INNER JOIN model.account ON project.account_id = account.id
			INNER JOIN model.organization ON account.organization_id = organization.id
		GROUP BY project.id
	;

CREATE OR REPLACE FUNCTION model.add_project_config(
	project_name TEXT,
	account_name TEXT,
	organization_name TEXT,
	tasks TEXT[], 
	members uuid[], 
	properties JSONB) RETURNS model.project_config AS
$$
DECLARE
	project model.project;
	organization model.organization;
	account	model.account;
	membership	model.membership;
	person	model.person;
	person_id uuid;
	task TEXT;
    pc model.project_config;

BEGIN
	SELECT * FROM model.organization t WHERE t.name = organization_name INTO organization;
	IF organization IS NULL THEN
		INSERT INTO model.organization(name) VALUES(organization_name) RETURNING * INTO organization;
	END IF;

	SELECT * FROM model.account t WHERE t.name = account_name INTO account;
	IF account IS NULL THEN
		INSERT INTO model.account(name, organization_id) VALUES(account_name, organization.id)  RETURNING * INTO account;
	END IF;

	SELECT * FROM model.project t WHERE t.name = project_name INTO project;
	IF project IS NULL THEN
		INSERT INTO model.project(name, account_id) VALUES(project_name, account.id) RETURNING * INTO project;
	END IF;
	
	FOREACH task IN ARRAY tasks
	LOOP
		INSERT INTO model.task(name, project_id) VALUES(task, project.id);
	END LOOP;

	FOREACH person_id IN ARRAY members
	LOOP
		SELECT * FROM model.person t WHERE t.id = person_id INTO person;
		INSERT INTO model.membership(person_id, project_id) 
			VALUES(person_id, project.id) 
			RETURNING * INTO membership;
		INSERT INTO model.rate(membership_id, rate, currency) 
			VALUES(membership.id, (person.properties->>'default_rate')::NUMERIC, person.properties->>'default_currency');
	END LOOP;

	SELECT * FROM model.project_config WHERE model.project_config.id = project.id INTO pc; 
	RETURN pc;
END; 
$$ LANGUAGE PLPGSQL;
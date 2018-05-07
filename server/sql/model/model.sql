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

CREATE TABLE IF NOT EXISTS model.account(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	customer_id uuid REFERENCES model.organization(id) ON DELETE CASCADE NOT NULL,
	vendor_id uuid REFERENCES model.organization(id) ON DELETE CASCADE NOT NULL,
	host_id uuid REFERENCES model.organization(id) ON DELETE CASCADE,
	name TEXT UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

CREATE TABLE IF NOT EXISTS model.person(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	name TEXT,
	email model.email UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

CREATE TABLE IF NOT EXISTS model.project(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	account_id uuid REFERENCES model.account(id) ON DELETE CASCADE NOT NULL,
	name TEXT UNIQUE,
	properties JSONB DEFAULT '{}' NOT NULL
);

DO $$
	BEGIN
		PERFORM * FROM pg_catalog.pg_indexes WHERE indexname = 'unique_docid_per_project_idx';
		IF NOT FOUND THEN
			CREATE UNIQUE INDEX unique_docid_per_project_idx ON model.project((properties->>'docid'));
		END IF;
	END;
$$ LANGUAGE PLPGSQL;

CREATE TABLE IF NOT EXISTS model.membership(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id) ON DELETE CASCADE NOT NULL,
	person_id uuid REFERENCES model.person(id) ON DELETE CASCADE NOT NULL,
	name TEXT NOT NULL,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_resource_name_per_project UNIQUE (project_id, name)
);


CREATE TABLE IF NOT EXISTS model.rate(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	membership_id uuid REFERENCES model.membership(id) ON DELETE CASCADE NOT NULL,
	rate NUMERIC NOT NULL,
	basis TEXT DEFAULT 'hourly' NOT NULL,
	discount NUMERIC DEFAULT 0.0 NOT NULL,
	currency CHAR(3) REFERENCES model.iso4217(code) NOT NULL,
	valid TIMESTAMPTZ DEFAULT NOW() NOT NULL,
	CONSTRAINT unique_rate_per_resource_per_project UNIQUE (membership_id, basis)
);

CREATE TABLE IF NOT EXISTS model.task(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	project_id uuid REFERENCES model.project(id) ON DELETE CASCADE NOT NULL,
	name TEXT,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_task_name_per_project UNIQUE (project_id, name)
);

CREATE TABLE IF NOT EXISTS model.entry(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	membership_id uuid REFERENCES model.membership(id) ON DELETE CASCADE NOT NULL,
	start_datetime timestamptz NOT NULL,
	stop_datetime timestamptz NOT NULL,
	task_id uuid REFERENCES model.task(id) NOT NULL,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT unique_entry UNIQUE(membership_id, start_datetime, stop_datetime),
	CONSTRAINT start_before_stop CHECK(start_datetime < stop_datetime),
	CONSTRAINT maximum_duration CHECK((stop_datetime - start_datetime) < INTERVAL '14 hours'),
	CONSTRAINT only_past CHECK(start_datetime <= NOW() AND stop_datetime <= NOW())
);

SELECT audit.add_audit(schemaname, tablename) FROM (
	SELECT schemaname, tablename
		FROM pg_catalog.pg_tables
			LEFT JOIN pg_catalog.pg_trigger ON tgname = 'trigger_insert_entity_' || tablename
		WHERE schemaname = 'model' AND tgname IS null
) t;

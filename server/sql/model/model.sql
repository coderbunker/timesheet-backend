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

CREATE OR REPLACE VIEW model.timesheet AS
	SELECT
		entry.id AS id,
		project.id AS project_id,
		membership.id AS membership_id,
		account.id AS account_id,
		customer.id AS customer_id,
		vendor.id AS vendor_id,
		person.id AS person_id,
		customer.name AS customer_name,
		vendor.name AS vendor_name,
		project.name AS project_name,
		account.name AS account_name,
		person.name AS person_name,
		membership.name AS membership_name,
		entry.start_datetime AS start_datetime,
		entry.stop_datetime AS stop_datetime,
		person.email AS email,
		task.name AS task_name,
		entry.properties AS properties,
		rate.currency AS currency,
		rate.rate AS rate,
		(stop_datetime-start_datetime) AS duration,
		utils.to_numeric_hours(stop_datetime-start_datetime) * (rate*(1-COALESCE(discount, 0))) AS total,
		utils.to_numeric_hours(stop_datetime-start_datetime) * (rate*COALESCE(discount, 0)) AS total_discount
	FROM model.entry
		INNER JOIN model.membership ON entry.membership_id = membership.id
		INNER JOIN model.task ON entry.task_id = task.id
		INNER JOIN model.person ON membership.person_id = person.id
		INNER JOIN model.project ON membership.project_id = project.id
		INNER JOIN model.account ON project.account_id = account.id
		INNER JOIN model.organization AS vendor ON account.vendor_id = vendor.id
		INNER JOIN model.organization AS customer ON account.customer_id = customer.id
		INNER JOIN model.rate ON membership.id = rate.membership_id
		INNER JOIN model.iso4217 ON rate.currency = iso4217.code
	;


CREATE OR REPLACE VIEW model.project_config AS
	SELECT
		project.id AS id,
		project.name AS project_name,
		max(customer.name) AS customer_name,
		max(vendor.name) AS vendor_name,
		max(account.name) AS account_name,
		array_agg(DISTINCT(task.name)) AS tasks,
		array_agg(DISTINCT(person.name)) AS members,
		array_agg(DISTINCT(membership.id)) AS membership_ids,
		array_agg(DISTINCT(task.id)) AS task_ids
		FROM model.project
			INNER JOIN model.membership ON membership.project_id = project.id
			INNER JOIN model.person ON membership.person_id = person.id
			INNER JOIN model.task ON task.project_id = project.id
			INNER JOIN model.account ON project.account_id = account.id
			INNER JOIN model.organization AS customer ON account.customer_id = customer.id
			INNER JOIN model.organization AS vendor ON account.vendor_id = vendor.id
		GROUP BY project.id
		;

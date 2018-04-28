CREATE SCHEMA IF NOT EXISTS model;

CREATE OR REPLACE FUNCTION model.add_person(
	name_ text DEFAULT 'Ritchie Kernighan', 
	email_ TEXT DEFAULT 'ritchie.kernighan@coderbunker.com',
	properties_ JSONB DEFAULT $$ { 
				"default_rate": 700, 
				"default_currency": "RMB" 
				} $$
) RETURNS model.person AS 
$testvalue$
	INSERT INTO model.person(name, email, properties)
		VALUES(
			name_,
			email_, 
			properties_
			)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.unique_name(TEXT) RETURNS text AS $$
	SELECT $1 || NOW() || random()
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_organization(name_ text DEFAULT model.unique_name('ORGANIZATION_NAME')) RETURNS model.organization AS 
$testvalue$
	INSERT INTO model.organization(name)
		VALUES(name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_account(customer uuid, vendor uuid, name_ text DEFAULT 'ACCOUNT_NAME') RETURNS model.account AS 
$testvalue$
	INSERT INTO model.account(customer_id, vendor_id, name)
		VALUES(customer, vendor, name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_project(account_id_ uuid, name_ text DEFAULT 'PROJECT_NAME', docid_ TEXT DEFAULT 'e3b6c540-5570-4111-b468-34169254115a') RETURNS model.project AS 
$testvalue$
	INSERT INTO model.project(name, account_id, properties)
		VALUES(name_, account_id_, format('{"docid": "%s"}', docid_)::jsonb)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_membership(project_id_ uuid, person_id_ uuid, rate_ NUMERIC DEFAULT 700, currency_ text DEFAULT 'RMB') RETURNS model.membership AS 
$testvalue$
DECLARE
	membership model.membership;
BEGIN
	INSERT INTO model.membership(project_id, person_id, name)
		VALUES(project_id_, person_id_, '')
		RETURNING * INTO membership
	;
	INSERT INTO model.rate(membership_id, rate, currency)
		VALUES(membership.id, rate_, currency_)
	;
	RETURN membership;
END;
$testvalue$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model.add_task(project_id_ uuid, name_ text DEFAULT 'TASK_NAME') RETURNS model.task AS 
$testvalue$
	INSERT INTO model.task(name, project_id)
		VALUES(name_, project_id_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_entry(
	membership_id_ uuid, 
	task_id_ uuid, 
	start_datetime_ timestamptz DEFAULT (NOW()- '1 hour'::INTERVAL), 
	stop_datetime_ timestamptz DEFAULT NOW()) 
RETURNS model.entry AS 
$testvalue$
	INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
		VALUES(membership_id_, task_id_, start_datetime_, stop_datetime_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION model.update_user() RETURNS model.person AS 
$testvalue$
	UPDATE model.person SET email = 'ritchie.kernighan@yahoo.com' 
		WHERE email = 'ritchie.kernighan@coderbunker.com'
		RETURNING *;
$testvalue$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION model.scenario1() RETURNS SETOF TEXT AS
$scenario1$
DECLARE
	person model.person;
	account model.account;
	project model.project;
	membership model.membership;
	task model.task;
	entry model.entry;
	customer model.organization;
	vendor model.organization;
BEGIN
	SELECT * FROM model.add_organization() INTO customer;
	SELECT * FROM model.add_organization() INTO vendor;
	SELECT * FROM model.add_person() INTO person;
	SELECT * FROM model.add_account(customer.id, vendor.id) INTO account;
	SELECT * FROM model.add_project(account.id) INTO project;
	SELECT * FROM model.add_membership(project.id, person.id) INTO membership;
	SELECT * FROM model.add_task(project.id) INTO task;
	SELECT * FROM model.add_entry(membership.id, task.id) INTO entry;
END;
$scenario1$ LANGUAGE plpgsql;

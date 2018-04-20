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

CREATE OR REPLACE FUNCTION model.add_organization(name_ text DEFAULT 'ORGANIZATION_NAME') RETURNS model.organization AS 
$testvalue$
	INSERT INTO model.organization(name)
		VALUES(name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_account(organization_id_ uuid, name_ text DEFAULT 'ACCOUNT_NAME') RETURNS model.account AS 
$testvalue$
	INSERT INTO model.account(organization_id, name)
		VALUES(organization_id_, name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_project(account_id_ uuid, name_ text DEFAULT 'PROJECT_NAME') RETURNS model.project AS 
$testvalue$
	INSERT INTO model.project(name, account_id)
		VALUES(name_, account_id_)
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

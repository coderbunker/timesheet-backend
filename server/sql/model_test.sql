CREATE EXTENSION IF NOT EXISTS pgtap;
DROP SCHEMA IF EXISTS model_test CASCADE;
CREATE SCHEMA IF NOT EXISTS model_test;

CREATE OR REPLACE FUNCTION model_test.add_person1(
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

CREATE OR REPLACE FUNCTION model_test.add_organization1(name_ text DEFAULT 'ORGANIZATION_NAME') RETURNS model.organization AS 
$testvalue$
	INSERT INTO model.organization(name)
		VALUES(name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_account1(organization_id_ uuid, name_ text DEFAULT 'ACCOUNT_NAME') RETURNS model.account AS 
$testvalue$
	INSERT INTO model.account(organization_id, name)
		VALUES(organization_id_, name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_project1(account_id_ uuid, name_ text DEFAULT 'PROJECT_NAME') RETURNS model.project AS 
$testvalue$
	INSERT INTO model.project(name, account_id)
		VALUES(name_, account_id_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_membership1(project_id_ uuid, person_id_ uuid, rate_ NUMERIC DEFAULT 700, currency_ text DEFAULT 'RMB') RETURNS model.membership AS 
$testvalue$
DECLARE
	membership model.membership;
BEGIN
	INSERT INTO model.membership(project_id, person_id)
		VALUES(project_id_, person_id_)
		RETURNING * INTO membership
	;
	INSERT INTO model.rate(membership_id, rate, currency)
		VALUES(membership.id, rate_, currency_)
	;
	RETURN membership;
END;
$testvalue$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.add_task1(project_id_ uuid, name_ text DEFAULT 'TASK_NAME') RETURNS model.task AS 
$testvalue$
	INSERT INTO model.task(name, project_id)
		VALUES(name_, project_id_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_entry1(
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


CREATE OR REPLACE FUNCTION model_test.update_user1() RETURNS model.person AS 
$testvalue$
	UPDATE model.person SET email = 'ritchie.kernighan@yahoo.com' 
		WHERE email = 'ritchie.kernighan@coderbunker.com'
		RETURNING *;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_performance() RETURNS SETOF TEXT AS 
$test_performance$
	SELECT model_test.add_person1();
	SELECT testutils.test_count_all_tables('model');
$test_performance$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_insert_entity() RETURNS SETOF TEXT AS 
$test_insert_entity$
DECLARE
	person model.person;
BEGIN
	SELECT * FROM model_test.add_person1() INTO person;
	RETURN QUERY SELECT results_eq(
		format($$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id = '%s' AND created IS NOT NULL AND updated is NULL 
		$$, person.id),
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
END;
$test_insert_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.test_update_entity() RETURNS SETOF TEXT AS 
$test_update_entity$
DECLARE
	person model.person;
BEGIN
	PERFORM model_test.add_person1();
	SELECT * FROM model_test.update_user1() INTO person;
	RETURN QUERY SELECT results_eq(
		format($query$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id = '%s' AND updated is NOT NULL;
		$query$, person.id),
		$expected$ VALUES ('model', 'person', CURRENT_USER::text) $expected$
	);
END;
$test_update_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.test_delete_entity() RETURNS SETOF TEXT AS 
$test_delete_entity$
DECLARE
	person model.person;
BEGIN
	PERFORM model_test.add_person1();
	SELECT * FROM model_test.update_user1() INTO person;
	DELETE FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com';
	RETURN QUERY SELECT results_eq(
		format($$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id = '%s' AND updated is NOT NULL AND deleted IS NOT NULL
		$$, person.id),
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
END;
$test_delete_entity$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION model_test.test_scenario1() RETURNS SETOF TEXT AS 
$test_scenario1$
DECLARE
	person model.person;
	account model.account;
	project model.project;
	membership model.membership;
	task model.task;
	entry model.entry;
	organization model.organization;
BEGIN
	SELECT * FROM model_test.add_organization1() INTO organization; 
	SELECT * FROM model_test.add_person1() INTO person;
	SELECT * FROM model_test.add_account1(organization.id) INTO account;
	SELECT * FROM model_test.add_project1(account.id) INTO project;
	SELECT * FROM model_test.add_membership1(project.id, person.id) INTO membership;
	SELECT * FROM model_test.add_task1(project.id) INTO task;
	SELECT * FROM model_test.add_entry1(membership.id, task.id) INTO entry;
	RETURN QUERY SELECT * FROM results_eq(
		format($$ SELECT account_name, email FROM model.timesheet WHERE id = '%s'; $$, entry.id),
		$$ VALUES ('ACCOUNT_NAME', 'ritchie.kernighan@coderbunker.com'::email); $$ 
	);
END;
$test_scenario1$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.test_insert_timesheet() RETURNS SETOF TEXT AS 
$test_insert_timesheet$
DECLARE
	person model.person;
	account model.account;
	project model.project;
	membership model.membership;
	task model.task;
	entry model.entry;
	organization model.organization;
	timesheet model.timesheet;
BEGIN
	SELECT * INTO organization FROM model_test.add_organization1('Coderbunker Test');
	SELECT * INTO account FROM model_test.add_account1(organization.id, 'Coderbunker');
	SELECT * INTO project FROM model_test.add_project1(account.id, 'Coderbunker Internal');
	SELECT * INTO person FROM model_test.add_person1('Ritchie Kernighan');
	SELECT * INTO membership FROM model_test.add_membership1(project.id, person.id);
	SELECT * INTO task FROM model_test.add_task1(project.id, 'Planning');

	SELECT * INTO timesheet FROM model.add_entry(
		'Coderbunker Internal', 
		'ritchie.kernighan@coderbunker.com',
		NOW() - '1 HOUR'::INTERVAL,
		NOW(),
		'Planning',
		$$ {"activity": "ACTIVITY", "reference": "REFERENCE"} $$
		);
		
	RETURN query SELECT * FROM results_eq(
		format($$ 
			SELECT account_name, email, properties->>'activity' FROM model.timesheet WHERE id = '%s';
		$$, timesheet.id),
		$$ VALUES ('Coderbunker', 'ritchie.kernighan@coderbunker.com'::email, 'ACTIVITY') $$
	);
END;
$test_insert_timesheet$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.add_team() RETURNS SETOF model.person AS
$$
	SELECT  model_test.add_person1(name, email) FROM (
		VALUES 	('ritchie.kernighan@coderbunker.com', 'Ritchie Kernighan'),
			 	('stephen.wozniak@coderbunker.com', 'Stephen Wozniak'),
			  	('bill.gates@coderbunker.com', 'Bill Gates')
	) t(email, name);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_add_project_config() RETURNS SETOF TEXT AS 
$test_add_project_config$
DECLARE
	account model.account;
	project model.project;
	membership model.membership;
	task model.task;
	entry model.entry;
	organization model.organization;
	project_config model.project_config;
	person model.person;

BEGIN
	SELECT * FROM model_test.add_team() INTO person;

	SELECT * INTO project_config FROM model.add_project_config(
		'New Coderbunker Project', 
		'New Coderbunker Customer',
		'Coderbunker Munich',
		$$ {'Planning', 'Development', 'Testing'} $$,
		(SELECT array_agg(id) FROM model.person WHERE name IN ('Ritchie Kernighan', 'Stephen Wozniak', 'Bill Gates')),
		'{"codename": "project doom"}'::JSONB
	);
		
	RETURN query SELECT * FROM results_eq(
		format($$ 
			SELECT project_name, organization_name, account_name 
			FROM model.project_config 
			WHERE project_config.id = '%s'; 
		$$, project_config.id),
		$$ VALUES ('New Coderbunker Project', 'Coderbunker Munich', 'New Coderbunker Customer'); $$
	);
END;
$test_add_project_config$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.test_entry_update_updates_result() RETURNS SETOF TEXT AS 
$test_entry_update_updates_result$
DECLARE
	project_config model.project_config;
	person model.person;
BEGIN
	SELECT * FROM model_test.add_team() INTO person;

	SELECT * INTO project_config FROM model.add_project_config(
		'New Coderbunker Project', 
		'New Coderbunker Customer',
		'Coderbunker Munich',
		$$ {'Planning', 'Development', 'Testing'} $$,
		(SELECT array_agg(id) FROM model.person WHERE name IN ('Ritchie Kernighan', 'Stephen Wozniak', 'Bill Gates')),
		'{"codename": "project moon laser"}'::JSONB
	);
		
	RETURN query SELECT * FROM is_empty(
		format($$ 
			SELECT total_entry 
			FROM report.project 
			WHERE project_id = '%s'; 
		$$, project_config.id)
	);
	
	INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
		VALUES(
			project_config.membership_ids[1], 
			project_config.task_ids[1], 
			NOW() - INTERVAL '1 hour', 
			NOW());
	
	RETURN query SELECT * FROM results_eq(
		format($$ 
			SELECT total_entry 
			FROM report.project 
			WHERE project_id = '%s'; 
		$$, project_config.id),
		$$ VALUES (INTERVAL '1 hour'); $$
	);
END;
$test_entry_update_updates_result$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION model_test.test_ledger() RETURNS SETOF TEXT AS 
$test_ledger$
	SELECT * FROM model_test.add_team(); 
	INSERT INTO model.ledger(entity_id, amount) 
		VALUES 	((SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10), 
				((SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -10);
	SELECT results_eq(
		$$ 
		SELECT sum(amount) FROM model.ledger;
		$$,
		$$ VALUES (0::NUMERIC); $$
	);
$test_ledger$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_ledger_fail() RETURNS SETOF TEXT AS 
$test_ledger_fail$
	SELECT throws_like(
		$$ 
		SELECT * FROM model_test.add_team(); 
			INSERT INTO model.ledger(entity_id, amount) 
				VALUES ((SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10);
			INSERT INTO model.ledger(entity_id, amount) 
				VALUES ((SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -9);
		$$,
		'%balance of amount does not match, sum is 10%'
	);
$test_ledger_fail$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_add_team() RETURNS SETOF TEXT AS 
$crap$
	SELECT * FROM results_eq(
		$$
		SELECT name FROM model_test.add_team() ORDER BY name;
		$$,
		$$ VALUES  ('Bill Gates'), ('Ritchie Kernighan'), ('Stephen Wozniak') $$
	);
$crap$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_bad_email() RETURNS SETOF TEXT AS 
$test_bad_email$
	SELECT * FROM throws_ok(
		$$
		INSERT INTO model.person(name, email, properties)
			VALUES(
				'ritchie.kernighan@coderbunker.com', -- email and name inverted on purpose
				'Ritchie Kernighan', 
				'{"default_rate": 700, "default_currency": "RMB"}'::JSONB
				)
		$$,
		'value for domain email violates check constraint "email_check"'
	);
$test_bad_email$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_email_case_insensitive() RETURNS SETOF TEXT AS 
$test_email_case_insensitive$
	SELECT * FROM throws_ok(
		$$
		INSERT INTO model.person(name, email, properties)
			VALUES ('Ritchie Kernighan', 'ritchie.kernighan@coderbunker.com', '{"default_rate": 700, "default_currency": "RMB"}'::JSONB),
			('Ritchie Kernighan', 'RITCHIE.KERNIGHAN@CODERBUNKER.COM', '{"default_rate": 700, "default_currency": "RMB"}'::JSONB)
		$$,
		'duplicate key value violates unique constraint "person_email_key"'
	);
$test_email_case_insensitive$ LANGUAGE SQL;

SELECT * FROM runtests( 'model_test'::name);





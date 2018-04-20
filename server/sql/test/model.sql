CREATE SCHEMA IF NOT EXISTS test;

CREATE OR REPLACE FUNCTION test.test_model_performance() RETURNS SETOF TEXT AS
$test_performance$
	SELECT model.add_person();
	SELECT test.count_all_tables('model');
$test_performance$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION test.test_model_insert_entity() RETURNS SETOF TEXT AS
$test_insert_entity$
DECLARE
	person model.person;
BEGIN
	SELECT * FROM model.add_person() INTO person;
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

CREATE OR REPLACE FUNCTION test.test_model_update_entity() RETURNS SETOF TEXT AS
$test_update_entity$
DECLARE
	person model.person;
BEGIN
	PERFORM model.add_person();
	SELECT * FROM model.update_user() INTO person;
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

CREATE OR REPLACE FUNCTION test.test_model_delete_entity() RETURNS SETOF TEXT AS
$test_delete_entity$
DECLARE
	person model.person;
BEGIN
	PERFORM model.add_person();
	SELECT * FROM model.update_user() INTO person;
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


CREATE OR REPLACE FUNCTION test.test_model_scenario1() RETURNS SETOF TEXT AS
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
	SELECT * FROM model.add_organization() INTO organization;
	SELECT * FROM model.add_person() INTO person;
	SELECT * FROM model.add_account(organization.id) INTO account;
	SELECT * FROM model.add_project(account.id) INTO project;
	SELECT * FROM model.add_membership(project.id, person.id) INTO membership;
	SELECT * FROM model.add_task(project.id) INTO task;
	SELECT * FROM model.add_entry(membership.id, task.id) INTO entry;
	RETURN QUERY SELECT * FROM results_eq(
		format($$ SELECT account_name, email FROM model.timesheet WHERE id = '%s'; $$, entry.id),
		$$ VALUES ('ACCOUNT_NAME', 'ritchie.kernighan@coderbunker.com'::email); $$
	);
END;
$test_scenario1$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_model_insert_timesheet() RETURNS SETOF TEXT AS
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
	SELECT * INTO organization FROM model.add_organization('Coderbunker Test');
	SELECT * INTO account FROM model.add_account(organization.id, 'Coderbunker');
	SELECT * INTO project FROM model.add_project(account.id, 'Coderbunker Internal');
	SELECT * INTO person FROM model.add_person('Ritchie Kernighan');
	SELECT * INTO membership FROM model.add_membership(project.id, person.id);
	SELECT * INTO task FROM model.add_task(project.id, 'Planning');

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

CREATE OR REPLACE FUNCTION model.add_team() RETURNS SETOF model.person AS
$$
	SELECT  model.add_person(name, email) FROM (
		VALUES 	('ritchie.kernighan@coderbunker.com', 'Ritchie Kernighan'),
			 	('stephen.wozniak@coderbunker.com', 'Stephen Wozniak'),
			  	('bill.gates@coderbunker.com', 'Bill Gates')
	) t(email, name);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.add_project_config() RETURNS model.project_config AS
$test_add_project_config$
DECLARE
	project_config model.project_config;
	person model.person;
BEGIN
	SELECT * FROM model.add_team() INTO person;

	SELECT * INTO project_config FROM model.add_project_config(
		'New Coderbunker Project',
		'New Coderbunker Customer',
		'Coderbunker Munich',
		$$ {'Planning', 'Development', 'Testing'} $$,
		(SELECT array_agg(id) FROM model.person WHERE name IN ('Ritchie Kernighan', 'Stephen Wozniak', 'Bill Gates')),
		'{"codename": "project doom"}'::JSONB
	);

	RETURN project_config;
END;
$test_add_project_config$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_model_add_project_config() RETURNS SETOF TEXT AS
$test_add_project_config$
DECLARE
	project_config model.project_config;
BEGIN

	SELECT * FROM model.add_project_config() INTO project_config;

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

CREATE OR REPLACE FUNCTION test.test_model_entry_update_updates_result() RETURNS SETOF TEXT AS
$test_entry_update_updates_result$
DECLARE
	project_config model.project_config;
BEGIN
	SELECT * FROM model.add_project_config() INTO project_config;

	RETURN query SELECT * FROM is_empty(
		format($$
			SELECT total_entry_hours
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
			SELECT total_entry_hours
			FROM report.project
			WHERE project_id = '%s';
		$$, project_config.id),
		$$ VALUES (1.0); $$
	);
END;
$test_entry_update_updates_result$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_model_ledger() RETURNS SETOF TEXT AS
$test_ledger$
	SELECT * FROM model.add_team();
	INSERT INTO model.ledger(source_id, destination_id, amount)
		VALUES 	('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10),
				('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -10);
	SELECT results_eq(
		$$
		SELECT sum(amount) FROM model.ledger;
		$$,
		$$ VALUES (0::NUMERIC); $$
	);
$test_ledger$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test.test_model_ledger_fail() RETURNS SETOF TEXT AS
$test_ledger_fail$
	SELECT throws_like(
		$$
		SELECT * FROM model.add_team();
			INSERT INTO model.ledger(source_id, destination_id, amount)
				VALUES ('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10);
			INSERT INTO model.ledger(entity_id, amount)
				VALUES ('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -9);
		$$,
		'%balance of amount does not match, sum is 10%'
	);
$test_ledger_fail$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test.test_model_add_team() RETURNS SETOF TEXT AS
$crap$
	SELECT * FROM results_eq(
		$$
		SELECT name FROM model.add_team() ORDER BY name;
		$$,
		$$ VALUES  ('Bill Gates'), ('Ritchie Kernighan'), ('Stephen Wozniak') $$
	);
$crap$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test.test_model_bad_email() RETURNS SETOF TEXT AS
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

CREATE OR REPLACE FUNCTION test.test_model_email_case_insensitive() RETURNS SETOF TEXT AS
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

CREATE OR REPLACE FUNCTION test.test_model_views_tables_performance() RETURNS SETOF TEXT AS
$test_email_case_insensitive$
BEGIN
	RETURN QUERY SELECT performs_ok(
		format('SELECT * FROM "%s"."%s";', schemaname, objectname),
		1000,
		format('check that %s.%s is fast enough (less than 1s)', schemaname, objectname)
		) FROM (
			SELECT schemaname, tablename AS objectname
				FROM pg_catalog.pg_tables
				WHERE schemaname = 'model' OR schemaname = 'report'
			UNION ALL
				SELECT schemaname, viewname AS objectname
					FROM pg_catalog.pg_views
					WHERE schemaname = 'model' OR schemaname = 'report'
		) t;
END;
$test_email_case_insensitive$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION test.test_model_cannot_add_negative_duration() RETURNS SETOF TEXT AS
$test_email_case_insensitive$
DECLARE
	project_config model.project_config;
BEGIN

	SELECT * FROM model.add_project_config() INTO project_config;
	RETURN QUERY SELECT throws_like(format($$
		INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
			VALUES(
				'%s',
				'%s',
				NOW(),
				NOW() - INTERVAL '1 hour'
		);
		$$, project_config.membership_ids[1], project_config.task_ids[1]),
		'%violates check constraint "start_before_stop"%'
	);
END;
$test_email_case_insensitive$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION test.test_model_cannot_add_excessive_duration() RETURNS SETOF TEXT AS
$test_cannot_add_excessive_duration$
DECLARE
	project_config model.project_config;
BEGIN

	SELECT * FROM model.add_project_config() INTO project_config;
	RETURN QUERY SELECT throws_like(format($$
		INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
			VALUES(
				'%s',
				'%s',
				NOW() - INTERVAL '14 hour',
				NOW()
		);
		$$, project_config.membership_ids[1], project_config.task_ids[1]),
		'%violates check constraint "maximum_duration"%'
	);
END;
$test_cannot_add_excessive_duration$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION test.test_model_cannot_add_entry_in_the_future() RETURNS SETOF TEXT AS
$test_cannot_add_entry_in_the_future$
DECLARE
	project_config model.project_config;
BEGIN

	SELECT * FROM model.add_project_config() INTO project_config;
	RETURN QUERY SELECT throws_like(format($$
		INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
			VALUES(
				'%s',
				'%s',
				NOW() - INTERVAL '1 hour',
				NOW() + INTERVAL '1 hour'
		);
		$$, project_config.membership_ids[1], project_config.task_ids[1]),
		'%violates check constraint "only_past"%'
	);

	RETURN QUERY SELECT throws_like(format($$
		INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime)
			VALUES(
				'%s',
				'%s',
				NOW() + INTERVAL '1 minute',
				NOW() + INTERVAL '1 hour'
		);
		$$, project_config.membership_ids[1], project_config.task_ids[1]),
		'%violates check constraint "only_past"%'
	);
END;
$test_cannot_add_entry_in_the_future$ LANGUAGE PLPGSQL;

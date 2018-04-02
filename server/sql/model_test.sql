DROP SCHEMA model_test CASCADE;
CREATE SCHEMA IF NOT EXISTS model_test;

CREATE OR REPLACE FUNCTION model_test.add_person1() RETURNS model.person AS 
$testvalue$
	INSERT INTO model.person(name, emails, nicknames, github)
		VALUES(
			'Ricky Ng-Adam', 
			'{"rngadam@coderbunker.com", "rngadam"}', 
			'{"Ricky", "伍思力"}',
			'rngadam')
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_account1() RETURNS model.account AS 
$testvalue$
	INSERT INTO model.account(name)
		VALUES('ACCOUNT_NAME')
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_project1(account_id_ uuid) RETURNS model.project AS 
$testvalue$
	INSERT INTO model.project(name, account_id)
		VALUES('PROJECT_NAME', account_id_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_member1(project_id_ uuid, person_id_ uuid) RETURNS model.member AS 
$testvalue$
	INSERT INTO model.member(project_id, person_id, hourly_rate, currency)
		VALUES(project_id_, person_id_, '700', 'RMB')
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_task1() RETURNS model.task AS 
$testvalue$
	INSERT INTO model.task(name)
		VALUES('TASK_NAME')
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_entry1(member_id_ uuid, task_id_ uuid) RETURNS model.entry AS 
$testvalue$
	INSERT INTO model.entry(member_id, task_id, start_datetime, stop_datetime)
		VALUES(member_id_, task_id_, now() - '1 hour'::INTERVAL, now())
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;


CREATE OR REPLACE FUNCTION model_test.update_user1() RETURNS model.person AS 
$testvalue$
	UPDATE model.person SET nicknames = nicknames || '{kiki}' 
		WHERE emails[1] = 'rngadam@coderbunker.com'
		RETURNING *;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_email() RETURNS SETOF TEXT AS 
$test_email$
	SELECT model_test.add_person1();
	SELECT results_eq(
		'SELECT emails[1] FROM model.person',
		$$ VALUES ('rngadam@coderbunker.com') $$)
	; 
$test_email$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_count() RETURNS SETOF TEXT AS 
$test_count$
	SELECT model_test.add_person1();
	SELECT results_eq(
		$$ 
			SELECT count(*)::integer FROM model.person
		$$,
		$$ VALUES (1::INTEGER) $$)
	; 
$test_count$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_performance() RETURNS SETOF TEXT AS 
$test_performance$
	SELECT model_test.add_person1();
	SELECT testutils.test_count_all_tables('model');
$test_performance$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_insert_entity() RETURNS SETOF TEXT AS 
$test_entity$
	SELECT model_test.add_person1();
	SELECT results_eq(
		$$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id IS NOT NULL AND created IS NOT NULL AND updated is NULL 
		$$,
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
$test_entity$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_update_entity() RETURNS SETOF TEXT AS 
$test_entity$
	SELECT model_test.add_person1();
	SELECT model_test.update_user1();
	SELECT results_eq(
		$$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id IS NOT NULL AND updated is NOT NULL
		$$,
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
$test_entity$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_delete_entity() RETURNS SETOF TEXT AS 
$test_entity$
	SELECT model_test.add_person1();
	SELECT model_test.update_user1();
	DELETE FROM model.person WHERE emails[1] = 'rngadam@coderbunker.com';
	SELECT results_eq(
		$$ 
			SELECT schema_name, table_name, userid 
			FROM audit.entity 
			WHERE id IS NOT NULL AND updated is NOT NULL AND deleted IS NOT NULL
		$$,
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
$test_entity$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION model_test.test_scenario1() RETURNS SETOF TEXT AS 
$test_entity$
DECLARE
	person model.person;
	account model.account;
	project model.project;
	member model.member;
	task model.task;
	entry model.entry;
BEGIN
	SELECT * FROM model_test.add_person1() INTO person;
	SELECT * FROM model_test.add_account1() INTO account;
	SELECT * FROM model_test.add_project1(account.id) INTO project;
	SELECT * FROM model_test.add_member1(project.id, person.id) INTO member;
	SELECT * FROM model_test.add_task1() INTO task;
	SELECT * FROM model_test.add_entry1(member.id, task.id) INTO entry;
	RETURN QUERY SELECT * FROM results_eq(
		$$ SELECT account_name, email FROM model.timesheet $$,
		$$ VALUES ('ACCOUNT_NAME', 'rngadam@coderbunker.com') $$ 
	);
END;
$test_entity$ LANGUAGE plpgsql;

DELETE FROM model.person;
SELECT * FROM runtests( 'model_test'::name);


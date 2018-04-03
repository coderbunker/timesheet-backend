DROP SCHEMA model_test CASCADE;
CREATE SCHEMA IF NOT EXISTS model_test;

CREATE OR REPLACE FUNCTION model_test.add_person1(name_ text DEFAULT 'Ricky Ng-Adam') RETURNS model.person AS 
$testvalue$
	INSERT INTO model.person(name, emails, nicknames, github)
		VALUES(
			name_,
			'{"rngadam@coderbunker.com", "rngadam"}', 
			'{"Ricky", "伍思力"}',
			'rngadam')
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

CREATE OR REPLACE FUNCTION model_test.add_member1(project_id_ uuid, person_id_ uuid, hourly_rate_ NUMERIC DEFAULT 700, currency_ text DEFAULT 'RMB') RETURNS model.member AS 
$testvalue$
	INSERT INTO model.member(project_id, person_id, hourly_rate, currency)
		VALUES(project_id_, person_id_, hourly_rate_, currency_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_task1(name_ text DEFAULT 'TASK_NAME') RETURNS model.task AS 
$testvalue$
	INSERT INTO model.task(name)
		VALUES(name_)
		RETURNING *;
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.add_entry1(
	member_id_ uuid, 
	task_id_ uuid, 
	start_datetime_ timestamptz DEFAULT (NOW()- '1 hour'::INTERVAL), 
	stop_datetime_ timestamptz DEFAULT NOW()) 
RETURNS model.entry AS 
$testvalue$
	INSERT INTO model.entry(member_id, task_id, start_datetime, stop_datetime)
		VALUES(member_id_, task_id_, start_datetime_, stop_datetime_)
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
	organization model.organization;
BEGIN
	SELECT * FROM model_test.add_organization1() INTO organization; 
	SELECT * FROM model_test.add_person1() INTO person;
	SELECT * FROM model_test.add_account1(organization.id) INTO account;
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

CREATE OR REPLACE FUNCTION model_test.test_insert_timesheet() RETURNS SETOF TEXT AS 
$test_entity$
DECLARE
	person model.person;
	account model.account;
	project model.project;
	member model.member;
	task model.task;
	entry model.entry;
	organization model.organization;
	timesheet model.timesheet;
BEGIN
	SELECT * INTO organization FROM model_test.add_organization1('Coderbunker Shanghai');
	SELECT * INTO account FROM model_test.add_account1(organization.id, 'Coderbunker');
	SELECT * INTO project FROM model_test.add_project1(account.id, 'Coderbunker Internal');
	SELECT * INTO person FROM model_test.add_person1('Ricky Ng-Adam');
	SELECT * INTO MEMBER FROM model_test.add_member1(project.id, person.id);
	SELECT * INTO task FROM model_test.add_task1('Planning');

	SELECT * INTO entry FROM model.add_entry(
		'Coderbunker Internal', 
		'rngadam@coderbunker.com',
		NOW() - '1 HOUR'::INTERVAL,
		NOW(),
		'Planning',
		'ACTIVITY', 
		'REFERENCE'
		);
		
--	INSERT INTO model.timesheet(
--		organization_name,
--		account_name, 
--		project_name, 
--		start_datetime, 
--		stop_datetime, 
--		email,
--		task_name,
--		activity, 
--		reference) 
--		VALUES(
--			'Coderbunker Shanghai',
--			'Coderbunker',
--			'Coderbunker Internal',
--			NOW() - '1 HOUR'::INTERVAL,
--			NOW(),
--			'rngadam@coderbunker.com',
--			'Planning',
--			'ACTIVITY',
--			'http://www.coderbunker.com'
--		) RETURNING * INTO timesheet;
--
	RETURN query SELECT * FROM results_eq(
		$$ SELECT account_name, email, activity FROM model.timesheet $$,
		$$ VALUES ('Coderbunker', 'rngadam@coderbunker.com', 'ACTIVITY') $$
	);
END;
$test_entity$ LANGUAGE plpgsql;

SELECT * FROM runtests( 'model_test'::name);


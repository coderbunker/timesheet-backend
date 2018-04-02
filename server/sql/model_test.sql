CREATE SCHEMA IF NOT EXISTS model_test;

CREATE OR REPLACE FUNCTION model_test.add_user1() RETURNS void AS 
$testvalue$
	INSERT INTO model.person(fullname, emails, nicknames, github)
		VALUES(
			'Ricky Ng-Adam', 
			'{"rngadam@coderbunker.com", "rngadam"}', 
			'{"Ricky", "伍思力"}',
			'rngadam')
	;
$testvalue$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model_test.test_email() RETURNS SETOF TEXT AS 
$test_email$
	SELECT model_test.add_user1();
	SELECT results_eq(
		'SELECT emails[1] FROM model.person',
		$$ VALUES ('rngadam@coderbunker.com') $$)
	; 
$test_email$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_count() RETURNS SETOF TEXT AS 
$test_count$
	SELECT model_test.add_user1();
	SELECT results_eq(
		'SELECT count(*)::integer FROM model.person',
		$$ VALUES (1::INTEGER) $$)
	; 
$test_count$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_performance() RETURNS SETOF TEXT AS 
$test_performance$
	SELECT model_test.add_user1();
	SELECT testutils.test_count_all_tables('model');
$test_performance$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION model_test.test_entity() RETURNS SETOF TEXT AS 
$test_entity$
	SELECT model_test.add_user1();
	SELECT results_eq(
		'SELECT schema_name, table_name, userid FROM model.entity WHERE id IS NOT NULL AND created is NOT NULL',
		$$ VALUES ('model', 'person', CURRENT_USER::text) $$
	);
$test_entity$ LANGUAGE sql;

SELECT * FROM runtests( 'model_test'::name);
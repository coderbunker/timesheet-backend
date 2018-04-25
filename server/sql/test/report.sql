CREATE SCHEMA IF NOT EXISTS test;

CREATE OR REPLACE FUNCTION test.test_report_performance() RETURNS SETOF TEXT AS
$test_performance$
	SELECT model.add_person();
	SELECT test.count_all_tables('model');
$test_performance$ LANGUAGE sql;
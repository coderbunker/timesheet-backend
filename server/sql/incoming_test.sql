CREATE EXTENSION IF NOT EXISTS pgtap;
DROP SCHEMA IF EXISTS incoming_test CASCADE;

CREATE SCHEMA IF NOT EXISTS incoming_test;

CREATE OR REPLACE FUNCTION incoming_test.test_convert_stop() RETURNS SETOF TEXT AS 
$test_convert_stop$
BEGIN
	RETURN QUERY SELECT results_eq($$
		SELECT incoming.convert_stop('1 hour'::INTERVAL, '4 hour'::interval);
		$$, $$
			VALUES('4 hour'::interval);
		$$
	);
	RETURN QUERY SELECT results_eq($$
		SELECT incoming.convert_stop('4 hour'::INTERVAL, '1 hour'::interval);
		$$, $$
			VALUES('25 hour'::interval);
		$$
	);
END;
$test_convert_stop$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION incoming_test.test_no_entry_with_stop_before_start() RETURNS SETOF TEXT AS 
$test_no_entry_with_stop_before_start$
BEGIN
	
	RETURN QUERY SELECT is_empty($$
			SELECT * FROM incoming.entry WHERE start > stop;
		$$
	);
END;
$test_no_entry_with_stop_before_start$ LANGUAGE PLPGSQL;
SELECT * FROM runtests( 'incoming_test'::name);

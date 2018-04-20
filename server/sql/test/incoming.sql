CREATE SCHEMA IF NOT EXISTS test;

CREATE OR REPLACE FUNCTION test.test_incoming_convert_stop() RETURNS SETOF TEXT AS
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


CREATE OR REPLACE FUNCTION test.test_incoming_no_entry_with_stop_before_start() RETURNS SETOF TEXT AS
$test_no_entry_with_stop_before_start$
BEGIN
	RETURN QUERY SELECT is_empty($$
			SELECT * FROM incoming.entry WHERE start > stop;
		$$
	);
END;
$test_no_entry_with_stop_before_start$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION test.test_incoming_extract_percentage() RETURNS SETOF TEXT AS
$test$
BEGIN
	RETURN QUERY SELECT results_eq(
		$$ SELECT incoming.extract_percentage('100%'); $$,
		$$ VALUES(1.0::NUMERIC); $$
	);
	RETURN QUERY SELECT results_eq(
		$$ SELECT incoming.extract_percentage('0%'); $$,
		$$ VALUES(0.0::NUMERIC); $$
	);
	RETURN QUERY SELECT results_eq(
		$$ SELECT incoming.extract_percentage('0'); $$,
		$$ VALUES(0.0::NUMERIC); $$
	);
--	RETURN QUERY SELECT is(
--		$$ SELECT incoming.extract_percentage('%'); $$,
--		NULL::NUMERIC
--	);
--	RETURN QUERY SELECT is(
--		$$ SELECT incoming.extract_percentage(''); $$,
--		NULL::NUMERIC
--	);
END;
$test$ LANGUAGE PLPGSQL;

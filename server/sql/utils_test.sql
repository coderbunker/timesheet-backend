CREATE EXTENSION IF NOT EXISTS pgtap;
DROP SCHEMA IF EXISTS utils_test CASCADE;
CREATE SCHEMA IF NOT EXISTS utils_test;

CREATE OR REPLACE FUNCTION utils_test.test_to_numeric_hours() RETURNS SETOF TEXT AS 
$to_numeric_hours$
BEGIN
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.to_numeric_hours(now() - (now() - INTERVAL '30 minutes')); $$,
		$$ VALUES(0.5) $$
	);
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.to_numeric_hours(now() - (now() - INTERVAL '15 minutes')); $$,
		$$ VALUES(0.25) $$
	);
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.to_numeric_hours(now() - (now() - INTERVAL '10 minutes')); $$,
		$$ VALUES(0.166666666666667) $$
	);
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.to_numeric_hours(now() - (now() - INTERVAL '1 hour 10 minutes')); $$,
		$$ VALUES(1.16666666666667) $$
	);
END;
$to_numeric_hours$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION utils_test.test_trim_array() RETURNS SETOF TEXT AS 
$test_trim_array$
BEGIN
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.trim_array('["Sam Evers", " SamE"]'::json); $$,
		$$ VALUES(ARRAY [ 'Sam Evers', 'SamE' ]); $$
	);
END;
$test_trim_array$ LANGUAGE PLPGSQL;

SELECT * FROM runtests( 'utils_test'::name);

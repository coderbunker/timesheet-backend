CREATE OR REPLACE FUNCTION test.test_utils_to_numeric_hours() RETURNS SETOF TEXT AS
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


CREATE OR REPLACE FUNCTION test.test_utils_trim_array() RETURNS SETOF TEXT AS
$test_trim_array$
BEGIN
	RETURN QUERY SELECT results_eq(
		$$ SELECT utils.trim_array('["Sam Evers", " SamE"]'::json); $$,
		$$ VALUES(ARRAY [ 'Sam Evers', 'SamE' ]); $$
	);
END;
$test_trim_array$ LANGUAGE PLPGSQL;

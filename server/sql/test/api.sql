CREATE OR REPLACE FUNCTION test.test_api_snapshot_warnings() RETURNS SETOF text AS
$test_api_snapshot_warnings$
BEGIN
	RETURN QUERY SELECT results_eq($$
		SELECT *
			FROM api.snapshot('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}');
		$$, 
		$$ VALUES
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'apptype should be present in doc'), 
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'category should be present in doc') 
		$$
	);
END;
$test_api_snapshot_warnings$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION test.test_api_snapshot_ok() RETURNS SETOF text AS
$test_api_snapshot_ok$
BEGIN
	RETURN QUERY SELECT is_empty($$
		SELECT *
			FROM api.snapshot(
				'8344d193-f3ef-4e30-b9e9-e6b2641db5a8', 
				'{"apptype": "Spreadsheet", "category": "Timesheet"}
			');
		$$
	);
END;
$test_api_snapshot_ok$ LANGUAGE PLPGSQL;

	SELECT snapshot_json('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}');
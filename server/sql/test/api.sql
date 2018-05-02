CREATE OR REPLACE FUNCTION test.test_api_snapshot_warnings() RETURNS SETOF text AS
$test_api_snapshot_warnings$
BEGIN
	RETURN QUERY SELECT results_eq($$
		SELECT *
			FROM api.snapshot('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}')
			ORDER BY error;
		$$, 
		$$ VALUES
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'apptype should be present in doc'), 
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'category should be present in doc'), 
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'name should be present in doc'), 
			('8344d193-f3ef-4e30-b9e9-e6b2641db5a8', '{}'::jsonb, 'incoming.snapshot', 'timezone should be present in doc') 
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
				'{"apptype": "Spreadsheet", "category": "Timesheet", "name": "a document has no name", "timezone": "Asia/Shanghai"}
			');
		$$
	);
END;
$test_api_snapshot_ok$ LANGUAGE PLPGSQL;
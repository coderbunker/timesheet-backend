CREATE OR REPLACE FUNCTION test.test_model_ledger() RETURNS SETOF TEXT AS
$test_ledger$
DECLARE
	scenario1 test.scenario1_datatype;
BEGIN
	SELECT * FROM test.scenario1() INTO scenario1;
	
	RETURN QUERY SELECT * FROM results_eq(format($$
		SELECT source_id, target_id FROM model.customer_to_account_deposit(
			'%s'::uuid, '%s'::uuid, 100, 'RMB', NOW());
		$$, scenario1.customer, scenario1.account), 
		format($$ 
			VALUES(NULL::uuid, '%s'::uuid), ('%s'::uuid, '%s'::uuid); 
		$$, scenario1.customer, scenario1.customer, scenario1.account)
	);
	RETURN QUERY SELECT * FROM results_eq(format($$
		SELECT audit.get_name(source_id), audit.get_name(target_id), amount 
			FROM model.freelancer_payout('%s'::uuid, '%s'::uuid, 100::NUMERIC, 'RMB'::text, NOW())
			ORDER BY amount ASC;
		$$, scenario1.account, scenario1.person), 
		format($$ 
			VALUES
			('%s', '%s', 10::numeric), 
			('%s', '%s', 13::numeric), 
			('%s', '%s', 77::numeric); 
		$$, 
			audit.get_name(scenario1.account), audit.get_name(scenario1.vendor), 
			audit.get_name(scenario1.account), audit.get_name(scenario1.host),
			audit.get_name(scenario1.account), audit.get_name(scenario1.person)
		)
	);
	
END;
$test_ledger$ LANGUAGE PLPGSQL;
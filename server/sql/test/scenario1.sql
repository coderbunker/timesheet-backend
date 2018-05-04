DO $scenario1_datatype$
BEGIN
	PERFORM * FROM pg_catalog.pg_type 
		WHERE
			typname = 'scenario1_datatype'
		;
		
	IF NOT FOUND THEN
		CREATE TYPE test.scenario1_datatype AS (
			customer uuid,
			vendor uuid,
			host uuid,
			person uuid,
			account uuid,
			project uuid,
			membership uuid,
			task uuid,
			entry uuid
		);
	END IF;
END;
$scenario1_datatype$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.scenario1() 
RETURNS test.scenario1_datatype
AS
$scenario1$
DECLARE
	scenario1 test.scenario1_datatype;
BEGIN
	SELECT id FROM model.add_organization('customer') INTO scenario1.customer;
	SELECT id FROM model.add_organization('vendor') INTO scenario1.vendor;
	SELECT id FROM model.add_organization('host') INTO scenario1.host;
	SELECT id FROM model.add_person('freelancer') INTO scenario1.person;
	SELECT id FROM model.add_account(scenario1.customer, scenario1.vendor, 'account', scenario1.host) INTO scenario1.account;
	SELECT id FROM model.add_project(scenario1.account) INTO scenario1.project;
	SELECT id FROM model.add_membership(scenario1.project, scenario1.person) INTO scenario1.membership;
	SELECT id FROM model.add_task(scenario1.project) INTO scenario1.task;
	SELECT id FROM model.add_entry(scenario1.membership, scenario1.task) INTO scenario1.entry;
	RETURN scenario1;
END;
$scenario1$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_scenario1() RETURNS SETOF TEXT AS
$test_scenario1$
DECLARE
	scenario1 test.scenario1_datatype;
BEGIN
	SELECT * FROM test.scenario1() INTO scenario1;
	RETURN QUERY SELECT * FROM results_eq(format($$ 
		SELECT '%s' = (SELECT vendor_id FROM model.account WHERE id = '%s');
	$$, scenario1.vendor, scenario1.account), $$ VALUES(true)$$);
	RETURN QUERY SELECT * FROM results_eq(format($$ 
		SELECT COUNT(*)::NUMERIC FROM model.account WHERE id = '%s' AND host_id IS NOT NULL;
	$$, scenario1.account), $$ VALUES(1::NUMERIC)$$);
END;
$test_scenario1$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION test.test_audit_insert_entity() RETURNS SETOF TEXT AS
$test_insert_entity$
DECLARE
	person model.person;
BEGIN
	SELECT * FROM model.add_person() INTO person;
	RETURN QUERY SELECT results_eq(
		format($$
			SELECT table_name, userid
			FROM model.entity
			WHERE id = '%s' AND created IS NOT NULL AND updated is NULL
		$$, person.id),
		$$ VALUES ('person', CURRENT_USER::text) $$
	);
	RETURN QUERY SELECT results_eq(format($$
			SELECT audit.get_name('%s')
		$$, person.id),
		$$ VALUES('Ritchie Kernighan') $$
	);
	RETURN QUERY SELECT results_eq(format($$
			SELECT audit.get_type('%s')
		$$, person.id),
		$$ VALUES('person') $$
	);
END;
$test_insert_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_audit_update_entity() RETURNS SETOF TEXT AS
$test_update_entity$
DECLARE
	person model.person;
BEGIN
	PERFORM model.add_person();
	SELECT * FROM model.update_user() INTO person;
	RETURN QUERY SELECT results_eq(
		format($query$
			SELECT table_name, userid
			FROM model.entity
			WHERE id = '%s' AND updated is NOT NULL;
		$query$, person.id),
		$expected$ VALUES ('person', CURRENT_USER::text) $expected$
	);
END;
$test_update_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_audit_delete_entity() RETURNS SETOF TEXT AS
$test_delete_entity$
DECLARE
	person model.person;
BEGIN
	SELECT * FROM model.add_person() INTO person;
	DELETE FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com';
	RETURN QUERY SELECT results_eq(
		format($$
			SELECT table_name, userid
			FROM model.entity
			WHERE id = '%s' AND deleted IS NOT NULL
		$$, person.id),
		$$ VALUES ('person', CURRENT_USER::text) $$
	);
END;
$test_delete_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test.test_audit_get_name_get_type() RETURNS SETOF TEXT AS
$test_audit_get_name_get_type$
DECLARE
	scenario1 test.scenario1_datatype;
BEGIN
	SELECT * FROM test.scenario1() INTO scenario1;
	RETURN QUERY SELECT results_eq(format(
		$$ SELECT audit.get_type('%s'), audit.get_name('%s'); $$, scenario1.person, scenario1.person),
		$$ VALUES ('person', 'freelancer') $$
	);
	RETURN QUERY SELECT results_eq(format(
		$$ SELECT audit.get_type('%s'), audit.get_name('%s'); $$, scenario1.customer, scenario1.customer),
		$$ VALUES ('organization', 'customer') $$
	);
	RETURN QUERY SELECT results_eq(format(
		$$ SELECT audit.get_type('%s'), audit.get_name('%s'); $$, scenario1.host, scenario1.host),
		$$ VALUES ('organization', 'host') $$
	);
	RETURN QUERY SELECT results_eq(format(
		$$ SELECT audit.get_type('%s'), audit.get_name('%s'); $$, scenario1.vendor, scenario1.vendor),
		$$ VALUES ('organization', 'vendor') $$
	);
	RETURN QUERY SELECT results_eq(format(
		$$ SELECT audit.get_type('%s'), audit.get_name('%s'); $$, scenario1.account, scenario1.account),
		$$ VALUES ('account', 'account') $$
	);
END;
$test_audit_get_name_get_type$ LANGUAGE PLPGSQL;

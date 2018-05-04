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
	SELECT * FROM model.update_user() INTO person;
	DELETE FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com';
	RETURN QUERY SELECT results_eq(
		format($$
			SELECT table_name, userid
			FROM model.entity
			WHERE id = '%s' AND updated is NOT NULL AND deleted IS NOT NULL
		$$, person.id),
		$$ VALUES ('person', CURRENT_USER::text) $$
	);
END;
$test_delete_entity$ LANGUAGE plpgsql;
 
-- TODO: add test
--CREATE OR REPLACE FUNCTION test.test_audit_create_delete_create_entity() RETURNS SETOF TEXT AS
--$test_delete_entity$
--DECLARE
--	person model.person;
--BEGIN
--	SELECT * FROM model.add_person() INTO person;
--	DELETE FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com';
--	PERFORM model.add_person();
--	RETURN QUERY SELECT results_eq(
--		format($$
--			SELECT table_name, userid
--			FROM model.entity
--			WHERE id = '%s' AND deleted < created
--		$$, person.id),
--		$$ VALUES ('person', CURRENT_USER::text) $$
--	);
--END;
--$test_delete_entity$ LANGUAGE plpgsql;
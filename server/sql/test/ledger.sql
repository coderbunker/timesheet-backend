CREATE OR REPLACE FUNCTION test.test_model_ledger() RETURNS SETOF TEXT AS
$test_ledger$
	SELECT * FROM model.add_team();
	INSERT INTO model.ledger(source_id, destination_id, amount)
		VALUES 	('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10),
				('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -10);
	SELECT results_eq(
		$$
		SELECT sum(amount) FROM model.ledger;
		$$,
		$$ VALUES (0::NUMERIC); $$
	);
$test_ledger$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION test.test_model_ledger_fail() RETURNS SETOF TEXT AS
$test_ledger_fail$
	SELECT throws_like(
		$$
		SELECT * FROM model.add_team();
			INSERT INTO model.ledger(source_id, destination_id, amount)
				VALUES ('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'ritchie.kernighan@coderbunker.com'), 10);
			INSERT INTO model.ledger(entity_id, amount)
				VALUES ('46207d44-ddf3-4ecf-8c01-d88d56d56181', (SELECT id FROM model.person WHERE email = 'stephen.wozniak@coderbunker.com'), -9);
		$$,
		'%balance of amount does not match, sum is 10%'
	);
$test_ledger_fail$ LANGUAGE SQL;
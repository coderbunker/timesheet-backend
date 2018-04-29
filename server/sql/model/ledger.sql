CREATE SCHEMA IF NOT EXISTS model;

CREATE TABLE IF NOT EXISTS model.ledger(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	source_id uuid REFERENCES audit.entity(id) ON DELETE CASCADE,
	target_id uuid REFERENCES audit.entity(id) ON DELETE CASCADE NOT NULL,
	amount NUMERIC NOT NULL,
	currency CHAR(3) REFERENCES model.iso4217(code) NOT NULL,
	recorded TIMESTAMPTZ DEFAULT NOW() NOT NULL,
	properties JSONB DEFAULT '{}' NOT NULL,
	CONSTRAINT no_duplicate UNIQUE(source_id, target_id, amount, recorded)
);

--CREATE OR REPLACE FUNCTION model.check_double_entry_balance() RETURNS TRIGGER AS
--$check_double_entry_balance$
--DECLARE
--	balance NUMERIC;
--	debits NUMERIC;
--	credits NUMERIC;
--BEGIN
--	WITH outgoing AS (
--		SELECT source_id AS id, SUM(-amount) AS balance 
--			FROM model.ledger 
--			WHERE source_id IS NOT NULL
--			GROUP BY source_id
--	), incoming AS (
--		SELECT target_id AS id, 
--			SUM(amount) AS balance 
--			FROM model.ledger 
--			GROUP BY target_id
--	)
--	SELECT 
--		SUM(outgoing.balance)+SUM(incoming.balance) INTO balance
--		FROM incoming 
--			LEFT JOIN outgoing ON incoming.id = outgoing.id
--	;
--
--	IF balance <> 0 THEN
--		RAISE EXCEPTION 'balance of all accounts is non-zero: %',  balance;
--	END IF;
--	RETURN NEW;
--END
--$check_double_entry_balance$ LANGUAGE plpgsql;
--
DROP TRIGGER IF EXISTS check_double_entry_balance_trigger ON model.ledger;
--CREATE  TRIGGER check_double_entry_balance_trigger
--	AFTER INSERT OR UPDATE OR DELETE ON  model.ledger
--	FOR EACH STATEMENT EXECUTE PROCEDURE model.check_double_entry_balance();

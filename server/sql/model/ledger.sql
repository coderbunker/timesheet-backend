CREATE SCHEMA IF NOT EXISTS model;

CREATE TABLE IF NOT EXISTS model.ledger(
	id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
	source_id uuid REFERENCES audit.entity(id) ON DELETE CASCADE NOT NULL,
	target_id uuid REFERENCES audit.entity(id) ON DELETE CASCADE NOT NULL,
	amount NUMERIC NOT NULL,
	currency CHAR(3) REFERENCES model.iso4217(code) NOT NULL,
	recorded TIMESTAMPTZ DEFAULT NOW() NOT NULL,
	properties JSONB DEFAULT '{}' NOT NULL
);

CREATE OR REPLACE FUNCTION model.check_double_entry_balance() RETURNS TRIGGER AS
$$
DECLARE
	balance NUMERIC;
BEGIN
	SELECT SUM(amount) FROM model.ledger INTO balance;
	IF balance <> 0 THEN
		RAISE EXCEPTION 'balance of amount does not match, sum is %', balance;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_double_entry_balance_trigger ON model.ledger;
CREATE  TRIGGER check_double_entry_balance_trigger
	AFTER INSERT OR UPDATE OR DELETE ON  model.ledger
	FOR EACH STATEMENT EXECUTE PROCEDURE model.check_double_entry_balance();

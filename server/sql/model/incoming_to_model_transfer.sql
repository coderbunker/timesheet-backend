CREATE OR REPLACE FUNCTION model.symbol_to_currency(text)
  RETURNS text AS
$func$
DECLARE
	_code TEXT;
BEGIN
	IF $1 IS NULL THEN
		RETURN NULL;
	END IF; 

	SELECT code INTO _code FROM model.iso4217 WHERE code = $1;
	IF FOUND THEN
		RETURN $1;
	END IF;
	IF $1 = '¥' THEN
		RETURN 'RMB';
	END IF;

	IF $1 = '$' THEN
		-- one project in Singapore but paid in USD!
		RETURN 'USD';
	END IF;

	RAISE EXCEPTION 'No such currency symbol recognized %', $1;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION model.bootstrap(source_id uuid, target_id uuid, amount NUMERIC, currency TEXT, recorded TIMESTAMPTZ) RETURNS SETOF model.ledger AS
$bootstrap$
	INSERT INTO model.ledger(source_id, target_id, amount, currency, recorded) 
		VALUES(NULL, source_id, amount, currency, recorded) RETURNING *;
	INSERT INTO model.ledger(source_id, target_id, amount, currency, recorded) 
		VALUES(source_id, target_id, amount, currency, recorded) RETURNING *;
$bootstrap$ LANGUAGE SQL;

TRUNCATE model.ledger;
SELECT * FROM (
	SELECT model.bootstrap(customer_id, account_id, amount, model.symbol_to_currency(currency), transfer_datetime)
		FROM incoming.transfer
			INNER JOIN model.project ON (properties->>'docid' = project_id)
			INNER JOIN model.account ON (account_id = account.id)
) AS b;

CREATE OR REPLACE VIEW model.balance AS
	SELECT * FROM (
		WITH outgoing AS (
			SELECT 
				source_id AS id, 
				SUM(-amount) AS balance,
				currency
				FROM model.ledger 
				WHERE source_id IS NOT NULL
				GROUP BY source_id, currency
		), incoming AS (
			SELECT target_id AS id, 
				SUM(amount) AS balance,
				currency
				FROM model.ledger 
				GROUP BY target_id, currency
		)
		SELECT 
			COALESCE(incoming.id, outgoing.id) AS id,
			COALESCE(incoming.balance, 0) AS inflows,
			COALESCE(outgoing.balance, 0) AS outflows,
			COALESCE(incoming.currency, outgoing.currency) AS currency,
			COALESCE(outgoing.balance, 0) + incoming.balance AS account_balance 
			FROM incoming 
				LEFT JOIN outgoing ON incoming.id = outgoing.id
	) b NATURAL JOIN model.entity
	;
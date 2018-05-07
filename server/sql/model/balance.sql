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
			round(COALESCE(incoming.balance, 0), 2) AS inflows,
			round(COALESCE(outgoing.balance, 0), 2) AS outflows,
			COALESCE(incoming.currency, outgoing.currency) AS currency,
			round(COALESCE(outgoing.balance, 0) + incoming.balance, 2) AS account_balance,
			audit.get_name(COALESCE(incoming.id, outgoing.id)) AS name
			FROM incoming 
				LEFT JOIN outgoing ON incoming.id = outgoing.id
	) b NATURAL JOIN model.entity
	;
	
CREATE OR REPLACE VIEW model.ledger_details AS
	SELECT 
		audit.get_name(source_id) AS source_name,
		s.table_name AS source_type,
		audit.get_name(target_id) AS target_name,
		t.table_name AS target_type,
		ledger.*
	FROM model.ledger 
		INNER JOIN model.entity s ON source_id = s.id
		INNER JOIN model.entity t ON target_id = t.id
		;
CREATE OR REPLACE VIEW incoming.transfer AS
	SELECT 
		(ELEMENT->>'date')::timestamptz AS transfer_datetime,
		incoming.extract_currency(ELEMENT->>'total') AS currency,
		incoming.extract_rate(ELEMENT->>'total') AS amount,
		id AS project_id
	FROM incoming.raw_entry 
	WHERE 
		ELEMENT->>'taskname' ILIKE 'Deposit' OR
		ELEMENT->>'activity' ILIKE 'Deposit'
	;

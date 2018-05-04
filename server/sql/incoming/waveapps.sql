CREATE OR REPLACE VIEW incoming.raw_receivable AS
	SELECT
		json_array_elements((doc#>'{sheets, "Accounts Receivable Transactions", data}')::json) AS element,
		doc->>'timezone' AS timezone,
		id,
		doc->>'name' AS name
	FROM
		api.snapshot
	WHERE
		doc->>'apptype' = 'Spreadsheet'
		AND doc->>'category' = 'WaveApp'
	;

CREATE OR REPLACE VIEW incoming.receivable AS
	SELECT
		(replace(ELEMENT->>'date', '.', ''))::TIMESTAMPTZ AS transfer_datetime,
		ELEMENT->>'transaction' AS description,
		trans.extracted[1] AS detail,
		trans.extracted[2] AS entity,
		incoming.extract_rate(ELEMENT->>'debit') AS debit,
		incoming.extract_rate(ELEMENT->>'credit') AS credit,
		incoming.extract_rate(ELEMENT->>'balance') AS balance
	FROM
		incoming.raw_receivable
		LEFT JOIN LATERAL (
			SELECT
				regexp_split_to_array(ELEMENT->>'transaction', ' - ') AS extracted
			) AS trans
			ON TRUE
	WHERE length(ELEMENT->>'date') > 0;




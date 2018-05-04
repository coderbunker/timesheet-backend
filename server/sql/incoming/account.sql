 CREATE OR REPLACE VIEW incoming.raw_account AS
 	SELECT
		json_array_elements((doc#>'{sheets, Accounts, data}')::json) AS element,
		doc->>'timezone' AS timezone,
		id,
		doc->>'name' AS name
	FROM
		api.snapshot
	WHERE
		doc->>'apptype' = 'Spreadsheet'
		AND doc->>'category' = 'Leads & Opportunities'
		;

CREATE OR REPLACE VIEW incoming.account AS
	SELECT
		(ELEMENT->>'status') AS status,
		ELEMENT->>'client' AS client,
		ELEMENT->>'projectsummary' AS summary,
		(regexp_matches(ELEMENT->>'timesheet' , '([A-Za-z0-9_-]{44})'))[1]  AS project_id,
		'https://docs.google.com/spreadsheets/d/' || (regexp_matches(ELEMENT->>'timesheet' , '([A-Za-z0-9_-]{44})'))[1]  AS timesheet_url,
		ELEMENT->>'legalname' AS legal_name
	FROM incoming.raw_account AS ELEMENT
	WHERE
		length(ELEMENT->>'status') > 0 AND
		length(ELEMENT->>'client') > 0 AND
		length(ELEMENT->>'projectsummary') > 0
	;
CREATE OR REPLACE VIEW incoming.raw_people AS
	SELECT 
		json_array_elements((doc#>'{sheets, Balance, data}')::json) AS doc,
		id AS project_id
	FROM incoming.snapshot
	;
	
CREATE OR REPLACE VIEW incoming.people AS
	SELECT 
		project_id,
		(regexp_matches(doc->>'rate', '[0-9]*\.[0-9]'))[1] AS rate,
		(regexp_matches(doc->>'rate', '[^0-9\.]'))[1] AS currency,
		doc->>'resource' AS resource
	FROM incoming.raw_people
	WHERE length(doc->>'resource') > 0;
	;
	
SELECT * FROM incoming.people
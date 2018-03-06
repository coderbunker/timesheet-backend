CREATE EXTENSION unaccent;
CREATE OR REPLACE VIEW incoming.raw_people AS
	SELECT 
		json_array_elements((doc#>'{sheets, Balance, data}')::json) AS doc,
		id AS project_id
	FROM incoming.snapshot
	;

DROP VIEW incoming.people;
CREATE OR REPLACE VIEW incoming.people AS
	SELECT 	
		project_id,
		incoming.extract_rate(doc->>'rate') AS project_rate,
		incoming.extract_currency(doc->>'rate') AS currency,
		incoming.extract_freelancer(doc) AS resource,
		profile.*
	FROM incoming.raw_people LEFT JOIN incoming.profile ON (
		to_tsvector('english', 
			COALESCE(fullname, '') || ' ' 
			|| COALESCE(email, '') || ' ' 
			|| COALESCE(github, '') || ' '
			|| COALESCE(altnames, '')) @@ plainto_tsquery('english', unaccent(doc->>'resource')) 		
	)
	WHERE 
		fullname IS NOT NULL
	;

SELECT *
FROM incoming.people WHERE project_rate IS NULL;
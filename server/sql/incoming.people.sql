CREATE EXTENSION unaccent;
CREATE OR REPLACE VIEW incoming.c AS
	SELECT 
		json_array_elements((doc#>'{sheets, Balance, data}')::json) AS doc,
		id AS project_id
	FROM incoming.snapshot
	;

SELECT * FROM incoming.raw_people;

DROP VIEW incoming.people;
CREATE OR REPLACE VIEW incoming.people AS
	SELECT 	
		project_id,
		incoming.extract_rate(doc->>'rate') AS project_rate,
		incoming.extract_currency(doc->>'rate') AS currency,
		incoming.extract_freelancer(doc )AS resource,
		profile.*
	FROM incoming.raw_people LEFT JOIN incoming.profile ON (
		to_tsvector('english', 
			COALESCE(fullname, '') || ' ' 
			|| COALESCE(email, '') || ' ' 
			|| COALESCE(github, '') || ' '
			|| COALESCE(altnames, '')) @@ plainto_tsquery('english', doc->>'resource') 		
	)
--	WHERE 
--		length(COALESCE(doc->>'resource', '')) > 0 AND
--		length(COALESCE(doc->>'rate', '')) > 0

	;

SELECT * FROM incoming.profile WHERE fullname = 'David Yu';
SELECT  doc->>'resource' AS name FROM incoming.raw_people ORDER BY name ;
SELECT * FROM incoming.people;
SELECT * FROM incoming.raw_people WHERE doc->>'resource' ilike '%David%';

SELECT * FROM incoming.raw_people 
WHERE project_id =  '1F7TYweE11OqGyZZRZYmmMMHLDokhfyPHQMkdZKzV6Qs'
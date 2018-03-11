CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE OR REPLACE VIEW incoming.raw_people AS
	SELECT 
		json_array_elements((doc#>'{sheets, Balance, data}')::json) AS doc,
		id AS project_id
	FROM incoming.snapshot
	;

DROP VIEW IF EXISTS incoming.people_project CASCADE;
CREATE OR REPLACE VIEW incoming.people_project AS
	SELECT 	
		project_id,
		profile.email,
		-- todo: apply discount if available
		incoming.extract_rate(doc->>'rate') AS project_rate,
		incoming.extract_currency(doc->>'rate') AS currency
	FROM incoming.raw_people LEFT JOIN incoming.profile ON (incoming.search_profile(doc->>'resource') = profile.email)
	;

DROP VIEW IF EXISTS incoming.people CASCADE;
CREATE OR REPLACE VIEW incoming.people AS
	SELECT 	
		fullname, 
		email, 
		github, 
		altnames, 
		array_agg(DISTINCT doc->>'resource') AS nicknames
	FROM incoming.raw_people INNER JOIN incoming.profile ON (incoming.search_profile(doc->>'resource') = profile.email)
	GROUP BY profile.email, profile.fullname, profile.github, profile.altnames
	;
CREATE VIEW incoming.profile_raw AS
	SELECT
		json_array_elements((doc#>'{data}')::json) AS freelancer
	FROM
		incoming.snapshot
	WHERE doc->>'apptype' = 'Slides' AND doc->>'category' = 'Freelancers'
	;
		
SELECT * FROM incoming.profile_raw;
CREATE OR REPLACE VIEW incoming.profile AS
	SELECT 
		freelancer->>'fullname' AS fullname,
		freelancer->>'email' AS email,
		freelancer->>'github' AS github,
		freelancer->>'wechat' AS wechat,
		freelancer->>'status' AS status,
		freelancer->>'rate' AS rate,
		freelancer->>'rate' AS rate_currency,
		freelancer->>'keywords' AS keywords,
		freelancer->>'altnames' AS altnames
	FROM 
		incoming.profile_raw;

DROP VIEW incoming.profile_textsearch;
CREATE OR REPLACE VIEW incoming.profile_textsearch AS
	SELECT 
			email,
			setweight(to_tsvector(COALESCE(altnames, '')), 'A') || 
			setweight(to_tsvector(COALESCE(email, '')), 'B') || 
			setweight(to_tsvector(COALESCE(github, '')), 'C') || 
			setweight(to_tsvector(COALESCE(fullname, '')), 'D') AS textsearch
	FROM incoming.profile;

CREATE OR REPLACE FUNCTION incoming.search_profile(text) RETURNS text AS
$func$
DECLARE
	return_email text;
BEGIN
	SELECT 
		email INTO return_email 
		FROM incoming.profile_textsearch, plainto_tsquery(unaccent($1)) query
		WHERE query @@ textsearch
		ORDER BY ts_rank_cd(textsearch, query) DESC
		LIMIT 1;
	RETURN return_email;
END
$func$ LANGUAGE plpgsql IMMUTABLE;

-- SELECT search_profile('Stephane');
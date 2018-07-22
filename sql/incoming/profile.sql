CREATE OR REPLACE VIEW incoming.profile_raw AS
	SELECT
		jsonb_array_elements((doc#>'{data}')::jsonb) AS freelancer
	FROM
		api.snapshot
	WHERE doc->>'apptype' = 'Slides' AND doc->>'category' = 'Freelancers'
	;

CREATE OR REPLACE VIEW incoming.profile AS
	SELECT
		freelancer->>'fullname' AS fullname,
		freelancer->>'email' AS email,
		freelancer->>'github' AS github,
		freelancer->>'wechat' AS wechat,
		freelancer->>'status' AS status,
		freelancer->>'rate' AS rate,
		freelancer->>'keywords' AS keywords,
		utils.trim_array((freelancer->>'altnames')::jsonb) AS altnames
	FROM
		incoming.profile_raw;

DROP MATERIALIZED VIEW IF EXISTS incoming.profile_textsearch;
CREATE MATERIALIZED VIEW incoming.profile_textsearch AS
	SELECT
			email,
			setweight(to_tsvector(COALESCE(array_to_string(altnames, ','), '')), 'A') ||
			setweight(to_tsvector(COALESCE(email, '')), 'B') ||
			setweight(to_tsvector(COALESCE(github, '')), 'C') ||
			setweight(to_tsvector(COALESCE(fullname, '')), 'D') AS textsearch
	FROM incoming.profile;

DROP INDEX IF EXISTS incoming.profile_textsearch_index;
CREATE INDEX profile_textsearch_index ON incoming.profile_textsearch USING GIN(textsearch);

CREATE OR REPLACE FUNCTION incoming.f_unaccent(text)
  RETURNS text AS
$func$
	SELECT public.unaccent('public.unaccent', $1)  -- schema-qualify function and dictionary
$func$  LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.search_profile(text) RETURNS text AS
$func$
DECLARE
	return_email text;
BEGIN
	SELECT
		email INTO return_email
		FROM incoming.profile
		WHERE altnames @> array[ $1 ];

	IF NOT FOUND THEN
		SELECT
			email INTO return_email
			FROM incoming.profile_textsearch, plainto_tsquery(incoming.f_unaccent($1)) query
			WHERE query @@ textsearch
			ORDER BY ts_rank_cd(textsearch, query) DESC
			LIMIT 1;
	END IF;

	IF NOT FOUND THEN
		SELECT
			email INTO return_email
			FROM incoming.profile
			WHERE fullname ILIKE '%' || $1 || '%'
			LIMIT 1;
	END IF;

	RETURN return_email;
END
$func$ LANGUAGE plpgsql IMMUTABLE;

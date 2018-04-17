CREATE EXTENSION IF NOT EXISTS unaccent;

DROP VIEW incoming.raw_people CASCADE;
CREATE OR REPLACE VIEW incoming.raw_people AS
	SELECT
		jsonb_array_elements((doc#>'{sheets, Balance, data}')::jsonb) AS doc,
		id AS project_id
	FROM incoming.snapshot
	;

CREATE OR REPLACE VIEW incoming.people_project AS
	SELECT
		project_id,
		incoming.search_profile(doc->>'resource') AS email,
		(doc->>'resource') as resource,
		incoming.extract_percentage(doc->>'ratediscount')  AS project_rate_discount,
		incoming.extract_rate(doc->>'rate') AS project_rate,
		incoming.extract_currency(doc->>'rate') AS currency
	FROM incoming.raw_people
	;

DROP MATERIALIZED VIEW IF EXISTS incoming.nickname_to_email CASCADE;
CREATE MATERIALIZED VIEW incoming.nickname_to_email AS
	SELECT resource, email
	FROM incoming.people_project
	WHERE resource IS NOT NULL
	GROUP BY resource, email;

CREATE OR REPLACE VIEW incoming.people AS
	SELECT
		fullname,
		profile.email,
		github,
		altnames,
		nicknames
	FROM
		incoming.profile LEFT JOIN LATERAL (
			SELECT array_agg(resource) AS nicknames
			FROM incoming.nickname_to_email 
			WHERE nickname_to_email.email = profile.email
		) AS t ON TRUE
	;
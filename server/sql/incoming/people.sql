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
		incoming.extract_currency(doc->>'rate') AS currency,
		NULLIF(trim(doc->>'calendar'), '') AS calendar
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
	
CREATE OR REPLACE VIEW incoming.people_project_calendar AS
	SELECT 
		resource,
		email,
		project_id,
		(regexp_match(calendar, '.*src=([[a-z0-9\.]*)'))[1] || '@group.calendar.google.com'  AS calendar_id
	FROM incoming.people_project 
	WHERE calendar IS NOT NULL
	;
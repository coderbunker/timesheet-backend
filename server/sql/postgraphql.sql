CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS postgraphql;

DROP MATERIALIZED VIEW IF EXISTS postgraphql.people_month_gross;
CREATE MATERIALIZED VIEW postgraphql.people_month_gross AS
SELECT 
	encode(digest(email, 'md5'), 'hex') AS id, 
	gross_overall,
	billable_month 
	FROM report.gross_people 
	WHERE 
		gross_overall IS NOT NULL AND
		gross_overall > 0 AND
		email IS NOT NULL
	ORDER BY gross_overall desc;

DROP MATERIALIZED VIEW IF EXISTS postgraphql.organization;
CREATE MATERIALIZED VIEW postgraphql.organization AS
	SELECT 
		organization.*,
		now() AS last_refresh,
		(SELECT max(last_update) FROM incoming.project) AS last_update
	FROM report.organization;

DROP FUNCTION postgraphql.refresh_data;

CREATE FUNCTION postgraphql.refresh_data() RETURNS timestamptz AS
$$
	REFRESH MATERIALIZED VIEW postgraphql.organization;
	SELECT last_refresh FROM postgraphql.organization; 
$$ LANGUAGE SQL;

-- SELECT * FROM postgraphql.refresh_data();


-- DROP FUNCTION postgraphql.refresh_data_conditional;z
--CREATE OR REPLACE FUNCTION postgraphql.refresh_data_conditional(OUT last_refresh timestamptz, OUT last_update timestamptz, OUT last_refresh_now timestamptz) AS
--$$
--BEGIN
--	SELECT 
--		organization.last_refresh,
--		(CASE WHEN organization.last_refresh < (SELECT max(project.last_update) FROM incoming.project) THEN (select postgraphql.refresh_data()) ELSE organization.last_refresh END) FROM postgraphql.organization;	
--END;
--$$ LANGUAGE plpgsql;
--
--SELECT * FROM postgraphql.refresh_data_conditional();


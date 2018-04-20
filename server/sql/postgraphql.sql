CREATE SCHEMA IF NOT EXISTS postgraphql;

DROP MATERIALIZED VIEW IF EXISTS postgraphql.organization;
CREATE MATERIALIZED VIEW postgraphql.organization AS
	SELECT
		organization.*,
		now() AS last_refresh,
		(SELECT max(last_update) FROM incoming.project) AS last_update
	FROM report.organization;
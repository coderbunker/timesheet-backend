CREATE SCHEMA IF NOT EXISTS postgraphql;

DO $$
	BEGIN
		PERFORM * FROM pg_catalog.pg_matviews WHERE matviewname = 'organization' AND schemaname = 'postgraphql';
		IF NOT FOUND THEN
			CREATE MATERIALIZED VIEW postgraphql.organization AS
				SELECT
					organization.*,
					now() AS last_refresh,
					(SELECT max(last_update) FROM incoming.project) AS last_update
				FROM report.organization;
			CREATE UNIQUE INDEX postgraphql_organization_index ON postgraphql.organization(orgname);
		ELSE
			REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.organization;
		END IF;
	END;
$$ LANGUAGE PLPGSQL;

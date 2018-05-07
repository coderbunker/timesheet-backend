DO $$
	BEGIN
		PERFORM * 
			FROM pg_catalog.pg_matviews 
			WHERE matviewname = 'organization' AND 
				schemaname = 'postgraphql';
		IF NOT FOUND THEN
			CREATE MATERIALIZED VIEW postgraphql.organization AS
				SELECT
					organization.*,
					now() AS last_refresh,
					(SELECT max(last_update) FROM incoming.project) AS last_update
				FROM report.organization
				;
			CREATE UNIQUE INDEX postgraphql_organization_index ON postgraphql.organization(orgname);
		ELSE
			REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.organization;
		END IF;
	END;
$$ LANGUAGE PLPGSQL;

DO $$
	BEGIN
		PERFORM * 
			FROM pg_catalog.pg_matviews 
			WHERE matviewname = 'trailing_12m_gross' AND 
				schemaname = 'postgraphql';
		IF NOT FOUND THEN
			CREATE MATERIALIZED VIEW postgraphql.trailing_12m_gross AS
				SELECT
					trailing_12m_gross.*,
					now() AS last_refresh,
					(SELECT max(last_update) FROM incoming.project) AS last_update
				FROM report.trailing_12m_gross
				ORDER BY trailing_12m_gross.entry_year, trailing_12m_gross.entry_month
				;
			CREATE UNIQUE INDEX postgraphql_trailing_12m_gross_index ON postgraphql.trailing_12m_gross(entry_year, entry_month, vendor_name, currency);
		ELSE
			REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.trailing_12m_gross;
		END IF;
	END;
$$ LANGUAGE PLPGSQL;

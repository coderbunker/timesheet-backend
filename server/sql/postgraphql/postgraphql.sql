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
			WHERE matviewname = 'monthly_gross' AND 
				schemaname = 'postgraphql';
		IF NOT FOUND THEN
			CREATE MATERIALIZED VIEW postgraphql.monthly_gross AS
				SELECT
					monthly_gross.*,
					now() AS last_refresh,
					(SELECT max(last_update) FROM incoming.project) AS last_update
				FROM report.monthly_gross
				ORDER BY monthly_gross.entry_year, monthly_gross.entry_month
				;
			CREATE UNIQUE INDEX postgraphql_monthly_gross_index ON postgraphql.monthly_gross(entry_year, entry_month, vendor_name, currency);
		ELSE
			REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.monthly_gross;
		END IF;
	END;
$$ LANGUAGE PLPGSQL;

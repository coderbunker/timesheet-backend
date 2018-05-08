CREATE OR REPLACE FUNCTION postgraphql.refresh_report() RETURNS trigger AS
$refresh_report$
BEGIN
	PERFORM * 
		FROM pg_catalog.pg_matviews 
		WHERE matviewname = 'organization' AND 
			schemaname = 'postgraphql';
	IF FOUND THEN
		REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.organization;
	END IF;
	PERFORM * 
		FROM pg_catalog.pg_matviews 
		WHERE matviewname = 'monthly_gross' AND 
			schemaname = 'postgraphql';
	IF FOUND THEN
		REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.monthly_gross;
	END IF;
	RETURN NEW;
END;
$refresh_report$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS postgraphql_update ON model.entry;

CREATE TRIGGER postgraphql_update
    AFTER INSERT OR UPDATE ON model.entry
    FOR EACH STATEMENT
    EXECUTE PROCEDURE postgraphql.refresh_report();
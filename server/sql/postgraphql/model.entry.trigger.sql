CREATE OR REPLACE FUNCTION postgraphql.refresh_report() RETURNS trigger AS
$refresh_report$
BEGIN
	REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.organization;
	REFRESH MATERIALIZED VIEW CONCURRENTLY postgraphql.trailing_12m_gross;
	RETURN NEW;
END;
$refresh_report$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS postgraphql_update ON model.entry;

CREATE TRIGGER postgraphql_update
    AFTER INSERT OR UPDATE ON model.entry
    FOR EACH STATEMENT
    EXECUTE PROCEDURE postgraphql.refresh_report();
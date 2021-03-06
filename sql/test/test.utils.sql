CREATE OR REPLACE FUNCTION test.count_all_views(
	schemaname TEXT
) RETURNS SETOF TEXT AS $$
DECLARE
	query TEXT;
BEGIN
	RETURN QUERY SELECT performs_ok(
	    format('SELECT count(*) FROM %s.%s', t.schemaname, t.viewname),
	    250,
	    format('%s should complete in less than 250ms', format('SELECT count(*) FROM %s.%s', t.schemaname, t.viewname))
	) FROM (
		SELECT *
			FROM pg_catalog.pg_views
			WHERE pg_views.schemaname = count_all_views.schemaname
			AND pg_views.viewname NOT LIKE 'raw%'
			AND pg_views.viewname NOT LIKE '%warnings%'
	) AS t;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION test.count_all_tables(
	schemaname TEXT
) RETURNS SETOF TEXT AS $$
DECLARE
	query TEXT;
BEGIN
	RETURN QUERY SELECT performs_ok(
	    format('SELECT count(*) FROM %s.%s', t.schemaname, t.tablename),
	    250,
	    format('%s should complete in less than 250ms', format('SELECT count(*) FROM %s.%s', t.schemaname, t.tablename))
	) FROM (
		SELECT *
			FROM pg_catalog.pg_tables
			WHERE pg_tables.schemaname = count_all_tables.schemaname
	) AS t;
END;
$$ LANGUAGE plpgsql;

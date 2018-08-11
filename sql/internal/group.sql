DO $$
	BEGIN
		PERFORM *
			FROM pg_catalog.pg_matviews
			WHERE matviewname = 'group' AND
				schemaname = 'internal';
		IF NOT FOUND THEN
			CREATE MATERIALIZED VIEW internal.group AS
				SELECT
					"group".*,
					now() AS last_refresh
				FROM incoming.group
				;
			CREATE UNIQUE INDEX internal_group_index ON internal.group(email);
		ELSE
			REFRESH MATERIALIZED VIEW CONCURRENTLY internal.group;
		END IF;
	END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION utils.disconnect(dbname TEXT) RETURNS
TABLE(pid integer, terminated BOOLEAN) AS
$$
	SELECT pg_stat_activity.pid AS pid, pg_terminate_backend(pg_stat_activity.pid) AS terminated
	FROM pg_stat_activity
	WHERE pg_stat_activity.datname = $1
	  AND pid <> pg_backend_pid()
	  ;
$$ LANGUAGE SQL;
CREATE OR REPLACE VIEW incoming.project AS
	SELECT
		id,
		doc->>'name' AS name,
		doc->>'timezone' AS timezone,
		ts AS last_update
	FROM
		incoming.snapshot;
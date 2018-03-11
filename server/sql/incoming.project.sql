DROP VIEW incoming.project;
CREATE OR REPLACE VIEW incoming.project AS
	SELECT 
		id,
		doc->>'name' AS name,
		ts AS last_update
	FROM 
		incoming.snapshot;
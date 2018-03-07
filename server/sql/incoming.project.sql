DROP VIEW incoming.project;
CREATE OR REPLACE VIEW incoming.project AS
	SELECT 
		id,
		doc->>'name' AS name,
		ts AS last_update
	FROM 
		incoming.snapshot;
		

SELECT * FROM incoming.snapshot;
-- WHERE id = '1F7TYweE11OqGyZZRZYmmMMHLDokhfyPHQMkdZKzV6Qs';
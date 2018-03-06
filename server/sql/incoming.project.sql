CREATE OR REPLACE VIEW incoming.project AS
	SELECT 
		*
	FROM 
		incoming.snapshot;
		

SELECT ts FROM incoming.snapshot 
-- WHERE id = '1F7TYweE11OqGyZZRZYmmMMHLDokhfyPHQMkdZKzV6Qs';
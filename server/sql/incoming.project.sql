CREATE VIEW incoming.project AS
	SELECT 
		id, 
		name, 
		timezone, 
		ts AS last_updated
	FROM 
		incoming.snapshot;
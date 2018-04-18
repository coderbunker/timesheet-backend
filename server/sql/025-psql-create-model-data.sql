
DO $$ 
 BEGIN
	INSERT INTO model.organization(id, name, properties)
		VALUES 
			('46207d44-ddf3-4ecf-8c01-d88d56d56181', 'Coderbunker Shanghai', '{}'), 
			('dffae778-dd06-46c1-a4ee-b7bfce34f71d', 'Coderbunker Singapore', '{}')
	ON CONFLICT DO NOTHING;
 END;
$$;

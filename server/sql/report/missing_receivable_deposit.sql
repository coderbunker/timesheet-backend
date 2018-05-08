CREATE OR REPLACE VIEW incoming.report_missing_receivable_deposit AS 
	SELECT 
		transfer.transfer_datetime, 
		name,
		amount,
		currency,
		project_id
		FROM 
			incoming.transfer
			INNER JOIN incoming.project ON (transfer.project_id = project.id)
			LEFT JOIN incoming.receivable ON (
				receivable.transfer_datetime = transfer.transfer_datetime 
				AND abs((credit - amount)/amount) <= 0.06)
		WHERE credit IS NULL AND currency <> '$'
		ORDER BY transfer_datetime
		;
		
COMMENT ON VIEW 
	incoming.report_missing_receivable_deposit IS
	 'list deposits found in timesheet that are not in account receivables';
	 

-- Retrieve specifics using following query:
--SELECT * FROM incoming.transfer 
--	INNER JOIN incoming.project ON id = project_id 
--	WHERE name ILIKE '%Asiahub%'
--	ORDER BY transfer_datetime	
--	;
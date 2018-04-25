CREATE OR REPLACE VIEW incoming.entry_union AS (
		SELECT * 
			FROM incoming.entry_calendar
			WHERE start_datetime < NOW() AND stop_datetime < NOW()
	) 
	UNION 
	(
		SELECT * 
			FROM incoming.entry
			WHERE start_datetime < NOW() AND stop_datetime < NOW()
	) 
	;
CREATE OR REPLACE VIEW incoming.raw_entry_calendar AS
	SELECT
		json_array_elements((doc#>'{events}')::json) AS element,
		doc->>'timezone' AS timezone,
		id,
		doc->>'name' AS name
	FROM
		incoming.snapshot
	WHERE 
		doc->>'apptype' = 'Calendar' 
		AND doc->>'category' = 'Timesheet'
	;
		
CREATE OR REPLACE VIEW incoming.entry_calendar AS
	SELECT
		(ELEMENT->>'startTime')::timestamptz AS start_datetime,
		(ELEMENT->>'endTime')::timestamptz  AS stop_datetime,
		resource,
		-- ELEMENT->'creators'->>0 AS creator,
		project_id,
		-- raw_entry_calendar.id AS docid,
		trim(t[1]) AS taskname,
		trim(t[2]) AS activity
	FROM incoming.raw_entry_calendar 
		INNER JOIN incoming.people_project_calendar ON people_project_calendar.calendar_id = raw_entry_calendar.id
		JOIN LATERAL regexp_split_to_array(trim(ELEMENT->>'name'), ': ?') AS t ON t[2] IS NOT NULL
	;
CREATE OR REPLACE VIEW incoming.raw_entry AS
	SELECT
		json_array_elements((doc#>'{sheets, Timesheet, data}')::json) AS element,
		doc->>'timezone' AS timezone,
		id,
		doc->>'name' AS name
	FROM
		incoming.snapshot
	WHERE 
		doc->>'apptype' = 'Spreadsheet' 
		AND doc->>'category' = 'Timesheet'

	;
					
CREATE OR REPLACE VIEW incoming.entry AS
	SELECT
		DATE + START AS start_datetime,
		DATE + stop AS stop_datetime,
		stop - START AS duration,
		resource,
		project_id,
		taskname,
		activity
	FROM
		(
			SELECT
				(
					ELEMENT ->> 'date'
				)::TIMESTAMP WITH TIME ZONE AS DATE,
				(
					(regexp_matches(ELEMENT ->> 'start', '[0-9:]*'))[0]
				)::INTERVAL AS START,
				(
					(regexp_matches(ELEMENT ->> 'stop', '[0-9:]*'))[0]
				)::INTERVAL AS stop,
				COALESCE(element->> 'resource', element->> 'name')  AS resource,
				id AS project_id,
				ELEMENT->>'taskname' AS taskname,
				ELEMENT->>'activity' AS activity
			FROM incoming.raw_entry AS ELEMENT
			WHERE
				(length(ELEMENT->>'resource') > 0 OR length(ELEMENT->>'name') > 0) AND
				length(ELEMENT->>'date') > 0 
		) AS converted
	ORDER BY start_datetime
	;
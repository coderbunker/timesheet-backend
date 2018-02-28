CREATE OR REPLACE VIEW incoming.raw_entry AS
	SELECT
		json_array_elements(DATA) AS element,
		"timezone",
		id,
		name
	FROM
		incoming.snapshot
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
					ELEMENT ->> 'start'
				)::INTERVAL AS START,
				(
					ELEMENT ->> 'stop'
				)::INTERVAL AS stop,
				COALESCE(element->> 'resource', element->> 'name')  AS resource,
				id AS project_id,
				ELEMENT->>'taskname' AS taskname,
				ELEMENT->>'activity' AS activity
			FROM incoming.raw_entry AS ELEMENT
			WHERE
				length(ELEMENT->>'start') > 0 AND
				length(ELEMENT->>'stop') > 0 AND
				(length(ELEMENT->>'resource') > 0 OR (length(ELEMENT->>'name') > 0) AND
				length(ELEMENT->>'date') > 0 
		) AS converted

	ORDER BY start_datetime;
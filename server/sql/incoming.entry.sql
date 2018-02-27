CREATE VIEW incoming.entry AS
	SELECT
		DATE + START AS start_datetime,
		DATE + stop AS stop_datetime,
		stop - START AS duration,
		resource,
		project_id
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
				ELEMENT ->> 'resource' AS resource,
				id AS project_id
			FROM (
				SELECT
					json_array_elements(DATA) AS element,
					"timezone",
					id,
					name
				FROM
					incoming.snapshot
			) AS ELEMENT
		) AS converted
	ORDER BY start_datetime;
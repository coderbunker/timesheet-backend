CREATE OR REPLACE VIEW incoming.warnings AS
	SELECT * FROM
	(
		(
			SELECT
				to_json(profile.*) AS doc,
				'incoming.profile' AS table_name,
				'email must be present for all profiles' AS error
			FROM incoming.profile
			WHERE email IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'time entry is negative' AS error
			FROM incoming.entry
			WHERE EXTRACT(EPOCH FROM duration) < 0
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'no task name given' AS error
			FROM incoming.entry
			WHERE taskname IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'no activity name given' AS error
			FROM incoming.entry
			WHERE taskname IS NULL
		)
		UNION ALL
		(
			SELECT
				format('{"project_id": "%s"}', project_id)::json AS doc,
				'incoming.entry' AS table_name,
				'taskname is on average longer than activity - reversed?' AS error
			FROM incoming.entry
			WHERE activity IS NOT NULL AND taskname IS NOT NULL
			GROUP BY project_id
			HAVING avg(length(taskname)) > avg(length(activity))
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'resource is null or length 0' AS error
			FROM incoming.entry
			WHERE entry.resource IS NULL OR LENGTH(entry.resource) = 0
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'resource does not match anything in people' AS error
			FROM incoming.entry LEFT JOIN incoming.people ON(entry.resource = ANY(people.nicknames))
			WHERE people.fullname IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(people.*) AS doc,
				'incoming.people' AS table_name,
				'no email for a people entry' AS error
			FROM incoming.people
			WHERE people.email IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(raw_people.*) AS doc,
				'incoming.raw_people' AS table_name,
				'no key rate specified' AS error
			FROM incoming.raw_people
			WHERE doc->>'rate' IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(raw_people.*) AS doc,
				'incoming.raw_people' AS table_name,
				'no key rate specified' AS error
			FROM incoming.raw_people
			WHERE doc->>'rate' IS NULL
		)
		UNION ALL
		(
			SELECT
				to_json(entry.*) AS doc,
				'incoming.entry' AS table_name,
				'duration is negative' AS error
			FROM incoming.entry
			WHERE EXTRACT (epoch FROM duration) < 0
		)
		UNION ALL
		(
			SELECT
				(array_agg(to_json(people_project.*)))[1] AS doc,
				'incoming.people_project' AS table_name,
				format('multiple resource matches for resource " %s" email "%s" count "%s"', resource, email, count(*)) AS error
			FROM incoming.people_project
			GROUP BY project_id, email, resource
			HAVING count(*) > 1
		)
	) AS all_errors
	;




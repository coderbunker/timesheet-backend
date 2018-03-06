DROP VIEW incoming.warnings;
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
				'resource is null or length 0' AS error
			FROM incoming.entry
			WHERE entry.resource IS NULL OR LENGTH(entry.resource) = 0
		) 
--		UNION ALL
--		(
--			SELECT 
--				to_json(entry.*) AS doc,
--				'incoming.entry' AS table_name,
--				'resource does not match anything in people' AS error
--			FROM incoming.entry LEFT JOIN incoming.people ON(entry.resource = people.resource)
--			WHERE people.fullname IS NULL
--		) 
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
	) AS all_errors
	;

SELECT DISTINCT doc->>'project_id' FROM incoming.warnings;

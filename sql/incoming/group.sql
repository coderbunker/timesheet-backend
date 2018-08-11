CREATE OR REPLACE VIEW incoming."raw_group" AS
	SELECT
		doc->>'id' AS group_id,
		(regexp_matches(doc->>'email', '(.*)@coderbunker.com'))[1] AS label,
		doc->>'name' AS group_description,
		doc->>'email' AS group_email,
		k.keys AS members
	FROM api.snapshot
	LEFT JOIN LATERAL (SELECT ARRAY(SELECT * FROM jsonb_object_keys(snapshot.doc->'members')) AS keys) k ON true
	WHERE
		doc->>'apptype' = 'Groups'
		AND  doc->>'category' = 'Membership'
		AND k.keys[1] <> 'undefined'
	GROUP BY doc->>'name', doc->>'email', doc->>'id', k.keys, ts
	ORDER BY label ASC
	;


CREATE OR REPLACE VIEW incoming.group AS
	SELECT 
		COALESCE(profile.email, labeled.email) AS email,
		labeled.labels, 
		profile.fullname,
		profile.github,
		profile.wechat,
		COALESCE(regexp_split_to_array(lower(profile.status), ', +'), ARRAY[]::TEXT[]) AS status
	FROM (
		SELECT
			array_agg(label) AS labels,
			email
		FROM (
			SELECT
				group_id,
				label,
				unnest(members) AS email
			FROM incoming.raw_group
			ORDER BY label
		) t
		WHERE label NOT LIKE '%-client'
		GROUP BY email
	) labeled
	FULL JOIN incoming.profile ON profile.email = labeled.email
	;
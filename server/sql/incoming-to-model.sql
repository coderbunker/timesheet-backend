INSERT INTO model.person(name, email, properties) SELECT * FROM (
	WITH properties AS (
		SELECT 
			people.fullname AS name,
			safe_cast(incoming.profile.email, null::email) AS email,
			ARRAY[
				'wechat', 
				'github', 
				'status', 
				'default_rate',
				'default_currency',
				'nicknames',
				'altnames'
			] AS names, 
			array[
				to_jsonb(wechat), 
				to_jsonb((regexp_match(COALESCE(people.github, profile.github), '(\w*)$'))[1]), 
				to_jsonb(status), 
				to_jsonb((regexp_matches(COALESCE(rate, '250'), '[0-9]*\.?[0-9]'))[1]::NUMERIC), 
				to_jsonb((regexp_matches(COALESCE(rate, 'RMB'), '(RMB|USD|SGD|EUR)'))[1]),
				to_jsonb(nicknames),
				to_jsonb(people.altnames)
			] AS values
		FROM incoming.people 
			FULL OUTER join incoming.profile 
			ON people.email = profile.email
	)
	SELECT name, email, jsonb_object_agg(p.pname, p.pvalue) AS properties
		FROM properties 
			LEFT JOIN LATERAL UNNEST(properties.names, properties.values) AS p(pname, pvalue) 
			ON TRUE
		WHERE p.pvalue IS NOT null
		GROUP BY name, email
) converted
ON CONFLICT(email) 
	DO UPDATE SET properties = EXCLUDED.properties
	WHERE person.email = EXCLUDED.email
	AND person.properties != EXCLUDED.properties
;
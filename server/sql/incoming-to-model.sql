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
	SELECT name, email, jsonb_object_agg(pname, pvalue) AS properties
		FROM properties 
			LEFT JOIN LATERAL UNNEST(properties.names, properties.values) AS p(pname, pvalue) 
			ON TRUE
		WHERE pvalue IS NOT null
		GROUP BY name, email
) converted
ON CONFLICT(email) 
	DO UPDATE SET properties = EXCLUDED.properties
	WHERE person.email = EXCLUDED.email
	AND person.properties != EXCLUDED.properties
;

WITH organization AS (
	SELECT id AS organization_id FROM model.organization WHERE name = 'Coderbunker Shanghai'
),  properties AS (
		SELECT 
			client AS name,
			ARRAY[
				'status', 
				'summary', 
				'docid',
				'legal_name'
			] AS names, 
			array[
				to_jsonb(status), 
				to_jsonb(summary), 
				to_jsonb(project_id), 
				to_jsonb(legal_name)
			] AS values
		FROM incoming.account 
	)
INSERT INTO model.account(name, organization_id, properties)  
	SELECT name, organization.organization_id, jsonb_object_agg(pname, pvalue) AS properties
		FROM organization, properties 
			LEFT JOIN LATERAL UNNEST(properties.names, properties.values) AS p(pname, pvalue) 
			ON TRUE
		WHERE pvalue IS NOT null
		GROUP BY name, organization.organization_id
ON CONFLICT(name) 
	DO UPDATE SET properties = EXCLUDED.properties
	WHERE account.name = EXCLUDED.name
	AND account.properties != EXCLUDED.properties
;

INSERT INTO model.project(name, properties, account_id) SELECT * FROM (
	WITH properties AS (
		SELECT 
			id AS docid, 
			name AS project_name,
			ARRAY[
				'docid', 
				'last_update'
			] AS names, 
			array[
				to_jsonb(id), 
				to_jsonb(last_update)
			] AS values
		FROM incoming.project 
	)
	SELECT project_name AS name, jsonb_object_agg(pname, pvalue) AS properties, account.id AS account_id
		FROM properties 
			LEFT JOIN LATERAL UNNEST(properties.names, properties.values) AS p(pname, pvalue) ON TRUE
			LEFT JOIN model.account ON account.properties->>'docid' = docid
		WHERE pvalue IS NOT NULL AND account.properties IS NOT null
		GROUP BY project_name, account.id
) converted
ON CONFLICT(name) 
	DO UPDATE SET properties = EXCLUDED.properties
	WHERE project.properties->>'docid' = EXCLUDED.properties->>'docid'
	AND project.properties != EXCLUDED.properties
;
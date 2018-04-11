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

INSERT INTO model.membership(project_id, person_id, name, properties) SELECT * FROM (
	WITH properties AS (
		SELECT 
			resource,
			person.id AS person_id,
			project.id AS project_id,
			ARRAY[
				'email',
				'docid'
			] AS names, 
			array[
				to_jsonb(person.email), 
				to_jsonb(people_project.project_id)
			] AS values
		FROM incoming.people_project
			LEFT JOIN model.person ON people_project.email = person.email
			LEFT JOIN model.project ON people_project.project_id = project.properties->>'docid'
		WHERE project.id IS NOT NULL AND person.id IS NOT NULL
	)
	SELECT project_id, person_id, resource AS name, jsonb_object_agg(pname, pvalue) AS properties
		FROM properties 
			LEFT JOIN LATERAL UNNEST(properties.names, properties.values) AS p(pname, pvalue) ON TRUE
		WHERE pvalue IS NOT NULL 
		GROUP BY project_id, person_id, resource
) converted
ON CONFLICT(project_id, name) 
	DO NOTHING
;

INSERT INTO model.rate(membership_id, rate, currency, basis, valid) SELECT * FROM (
	WITH project_rate_validity AS (
		-- TODO: need to manage validity period
		SELECT project_id, resource, min(COALESCE(start_datetime, now())) AS start_datetime
			FROM incoming.entry
			GROUP BY project_id, resource
			HAVING min(start_datetime) IS NOT NULL
	)
	SELECT 
		membership.id AS membership_id, 
		project_rate AS rate, 
		'RMB' AS currency, -- TODO: get it from default_currency
		'hourly' AS basis, 
		start_datetime AS valid
	FROM model.membership 
		-- TODO: warn on missing entries
		INNER JOIN incoming.people_project 
			ON membership.properties->>'docid' = people_project.project_id 
				AND membership.name = people_project.resource
		INNER JOIN project_rate_validity 
			ON membership.properties->>'docid' = project_rate_validity.project_id 
				AND membership.name = project_rate_validity.resource
) converted
ON CONFLICT(membership_id, basis)
	DO NOTHING
;

INSERT INTO model.task(project_id, name) SELECT * FROM (
	WITH tasks AS (
		SELECT 
			DISTINCT(project_id, taskname),
			project_id, 
			taskname
		FROM incoming.entry 
		WHERE 
			taskname IS NOT NULL 
			AND length(trim(taskname)) > 0
			AND lower(taskname) != 'Deposit'
		GROUP BY project_id, taskname
	) 
	SELECT 
		model.project.id AS project_id, 
		taskname AS name 
	FROM tasks 
		INNER JOIN model.project 
			ON tasks.project_id = model.project.properties->>'docid'
) converted
ON CONFLICT(project_id, name)
	DO NOTHING
;

INSERT INTO model.entry(membership_id, task_id, start_datetime, stop_datetime) 
	SELECT membership.id AS membership_id, task.id AS task_id, start_datetime, stop_datetime 
	FROM incoming.entry 
		INNER JOIN incoming.project 
			ON project.id = entry.project_id
		INNER JOIN incoming.people_project 
			ON  project.id = people_project.project_id
		INNER JOIN model.project
			ON model.project.properties->>'docid' =  people_project.project_id
		INNER JOIN model.membership 
			ON people_project.resource = membership.name AND membership.project_id = model.project.id
		INNER JOIN model.task
			ON task.project_id = model.project.id
			AND task.name = taskname
ON CONFLICT(membership_id, start_datetime, stop_datetime)
	DO NOTHING
;
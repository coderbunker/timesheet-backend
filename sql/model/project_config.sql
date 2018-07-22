
CREATE OR REPLACE VIEW model.project_config AS
	SELECT
		project.id AS id,
		project.name AS project_name,
		max(customer.name) AS customer_name,
		max(vendor.name) AS vendor_name,
		max(account.name) AS account_name,
		array_agg(DISTINCT(task.name)) AS tasks,
		array_agg(DISTINCT(person.name)) AS members,
		array_agg(DISTINCT(membership.id)) AS membership_ids,
		array_agg(DISTINCT(task.id)) AS task_ids
		FROM model.project
			INNER JOIN model.membership ON membership.project_id = project.id
			INNER JOIN model.person ON membership.person_id = person.id
			INNER JOIN model.task ON task.project_id = project.id
			INNER JOIN model.account ON project.account_id = account.id
			INNER JOIN model.organization AS customer ON account.customer_id = customer.id
			INNER JOIN model.organization AS vendor ON account.vendor_id = vendor.id
		GROUP BY project.id
		;
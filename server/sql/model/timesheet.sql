CREATE OR REPLACE VIEW model.timesheet AS
	SELECT
		entry.id AS id,
		project.id AS project_id,
		membership.id AS membership_id,
		account.id AS account_id,
		customer.id AS customer_id,
		vendor.id AS vendor_id,
		person.id AS person_id,
		customer.name AS customer_name,
		vendor.name AS vendor_name,
		project.name AS project_name,
		account.name AS account_name,
		person.name AS person_name,
		membership.name AS membership_name,
		entry.start_datetime AS start_datetime,
		entry.stop_datetime AS stop_datetime,
		person.email AS email,
		task.name AS task_name,
		entry.properties AS properties,
		rate.currency AS currency,
		rate.rate AS rate,
		(stop_datetime-start_datetime) AS duration,
		utils.to_numeric_hours(stop_datetime-start_datetime) * (rate*(1-COALESCE(discount, 0))) AS total,
		utils.to_numeric_hours(stop_datetime-start_datetime) * (rate*COALESCE(discount, 0)) AS total_discount
	FROM model.entry
		INNER JOIN model.membership ON entry.membership_id = membership.id
		INNER JOIN model.task ON entry.task_id = task.id
		INNER JOIN model.person ON membership.person_id = person.id
		INNER JOIN model.project ON membership.project_id = project.id
		INNER JOIN model.account ON project.account_id = account.id
		INNER JOIN model.organization AS vendor ON account.vendor_id = vendor.id
		INNER JOIN model.organization AS customer ON account.customer_id = customer.id
		INNER JOIN model.rate ON membership.id = rate.membership_id
		INNER JOIN model.iso4217 ON rate.currency = iso4217.code
	;

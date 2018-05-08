CREATE OR REPLACE FUNCTION model.add_project_config(
	project_name TEXT,
	account_name TEXT,
	organization_name TEXT,
	tasks TEXT[], 
	members uuid[], 
	properties JSONB) RETURNS model.project_config AS
$add_project_config$
DECLARE
	project model.project;
	customer model.organization;
	vendor model.organization;
	account	model.account;
	membership	model.membership;
	person	model.person;
	person_id uuid;
	task TEXT;
    pc model.project_config;
BEGIN
	SELECT * FROM model.organization t WHERE t.name = organization_name INTO vendor;
	IF vendor IS NULL THEN
		INSERT INTO model.organization(name) VALUES(organization_name) RETURNING * INTO vendor;
	END IF;

	SELECT * FROM model.organization t WHERE t.name = account_name INTO customer;
	IF customer IS NULL THEN
		INSERT INTO model.organization(name) VALUES(account_name) RETURNING * INTO customer;
	END IF;

	SELECT * FROM model.account t WHERE t.name = account_name INTO account;
	IF account IS NULL THEN
		INSERT INTO model.account(name, customer_id, vendor_id) 
			VALUES(account_name, customer.id, vendor.id)  RETURNING * INTO account;
	END IF;

	SELECT * FROM model.project t WHERE t.name = project_name INTO project;
	IF project IS NULL THEN
		INSERT INTO model.project(name, account_id) VALUES(project_name, account.id) RETURNING * INTO project;
	END IF;
	
	FOREACH task IN ARRAY tasks
	LOOP
		INSERT INTO model.task(name, project_id) VALUES(task, project.id);
	END LOOP;

	FOREACH person_id IN ARRAY members
	LOOP
		SELECT * FROM model.person t WHERE t.id = person_id INTO person;
		INSERT INTO model.membership(person_id, project_id, name) 
			VALUES(person_id, project.id, person.name) 
			RETURNING * INTO membership;
		INSERT INTO model.rate(membership_id, rate, currency) 
			VALUES(membership.id, (person.properties->>'default_rate')::NUMERIC, person.properties->>'default_currency');
	END LOOP;

	SELECT * FROM model.project_config WHERE model.project_config.id = project.id INTO pc; 
	RETURN pc;
END; 
$add_project_config$ LANGUAGE PLPGSQL;
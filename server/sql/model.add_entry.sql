CREATE OR REPLACE FUNCTION model.add_entry(
	project_name TEXT,
	email_ TEXT,
	start_datetime TIMESTAMPTZ, 
	stop_datetime TIMESTAMPTZ, 
	task_name TEXT, 
	properties JSONB) RETURNS model.timesheet AS
$add_entry$
DECLARE
	entry model.entry;
	task model.task;
	project model.project;
	membership model.membership;
	ts model.timesheet;
BEGIN
	SELECT * INTO task FROM model.task t WHERE t.name = task_name;
	IF task IS NULL THEN
		RAISE EXCEPTION 'Nonexistent task --> %', task_name USING HINT = 'Create task';
	END IF;
	SELECT * INTO project FROM model.project WHERE name = project_name;
	IF project IS NULL THEN
		RAISE EXCEPTION 'Nonexistent project --> %', project_name USING HINT = 'Create project';
	END IF;
	SELECT * INTO membership
		FROM model.membership m
			INNER JOIN model.person p ON p.id = m.person_id 
		WHERE p.email = email_ AND m.project_id = project.id;
	IF membership IS NULL THEN
		RAISE EXCEPTION 'Nonexistent membership --> %', email_ USING HINT = 'Create membership with this email';
	END IF;

	INSERT INTO model.entry(
		start_datetime, 
		stop_datetime, 
		task_id, 
		membership_id,
		properties) 
	VALUES (
		start_datetime,
   		stop_datetime,
   		task.id,
   		membership.id,
   		properties) 
	RETURNING * INTO entry;

	SELECT * INTO ts 
		FROM model.timesheet t WHERE t.id = entry.id;

	RETURN ts;
END;
$add_entry$ LANGUAGE plpgsql;
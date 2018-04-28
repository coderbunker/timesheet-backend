CREATE SCHEMA IF NOT EXISTS audit;

CREATE OR REPLACE FUNCTION audit.insert_entity() RETURNS TRIGGER AS
$insert_entity$
BEGIN
	IF TG_TABLE_NAME = 'entity' THEN
		RETURN NEW;
	END IF;
	EXECUTE format($$
		INSERT INTO "%s".entity(id, table_name, userid) 
			VALUES ('%s', '%s', '%s');
	$$, TG_TABLE_SCHEMA, NEW.id, TG_TABLE_NAME, user);
	RETURN NEW;
END;
$insert_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.update_entity() RETURNS TRIGGER AS
$update_entity$
BEGIN
	IF TG_TABLE_NAME = 'entity' THEN
		RETURN NEW;
	END IF; 
	EXECUTE format($$
		UPDATE %s.entity SET updated = NOW() WHERE id = '%s';
	$$, TG_TABLE_SCHEMA, NEW.id);
	RETURN NEW;
END;
$update_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.delete_entity() RETURNS TRIGGER AS
$delete_entity$
BEGIN
	IF TG_TABLE_NAME = 'entity' THEN
		RETURN NEW;
	END IF;
	EXECUTE format($$
		UPDATE %s.entity SET deleted = NOW() WHERE id = '%s';
	$$, TG_TABLE_SCHEMA, NEW.id);
	RETURN NEW;
END;
$delete_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.add_audit(schema_name TEXT, table_name TEXT) RETURNS SETOF TEXT AS
$add_audit$
BEGIN
	
	PERFORM * FROM pg_catalog.pg_tables WHERE tablename = 'entity' AND schemaname = schema_name;
	IF NOT FOUND THEN
		EXECUTE format($$
			CREATE TABLE IF NOT EXISTS %s.entity(
				id uuid PRIMARY KEY,
				table_name TEXT NOT NULL,
				created TIMESTAMPTZ DEFAULT now() NOT NULL,
				updated TIMESTAMPTZ,
				deleted TIMESTAMPTZ,
				userid TEXT ) NOT NULL
			); $$, schema_name);
	END IF;

	EXECUTE format (
		 $$ CREATE TRIGGER %s AFTER INSERT ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.insert_entity() $$, 
		'trigger_insert_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		$$ CREATE TRIGGER %s AFTER UPDATE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.update_entity() $$,  
		'trigger_update_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		$$ CREATE TRIGGER %s AFTER UPDATE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.delete_entity() $$,  
		'trigger_delete_entity_' || table_name, schema_name, table_name);
	RETURN NEXT 'trigger_insert_entity_' || table_name;
	RETURN NEXT 'trigger_update_entity_' || table_name;
	RETURN NEXT 'trigger_delete_entity_' || table_name;
END;
$add_audit$ LANGUAGE plpgsql;
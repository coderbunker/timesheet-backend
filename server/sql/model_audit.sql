DROP SCHEMA audit CASCADE;
CREATE SCHEMA IF NOT EXISTS audit;

CREATE TABLE IF NOT EXISTS audit.entity(
	id uuid PRIMARY KEY,
	schema_name TEXT,
	table_name TEXT,
	created TIMESTAMPTZ DEFAULT now() NOT NULL,
	updated TIMESTAMPTZ,
	deleted TIMESTAMPTZ,
	userid TEXT
);

CREATE OR REPLACE FUNCTION audit.insert_entity() RETURNS TRIGGER AS
$$
BEGIN
	INSERT INTO audit.entity(id, schema_name, table_name, userid) VALUES (NEW.id, TG_TABLE_SCHEMA, TG_TABLE_NAME, user);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.update_entity() RETURNS TRIGGER AS
$$
BEGIN
	UPDATE audit.entity SET updated = NOW() WHERE id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.delete_entity() RETURNS TRIGGER AS
$$
BEGIN
	UPDATE audit.entity SET deleted = NOW() WHERE id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.add_audit(schema_name TEXT, table_name TEXT) RETURNS SETOF TEXT AS
$$
BEGIN
	EXECUTE format (
		'CREATE TRIGGER %s AFTER INSERT ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.insert_entity()', 
		'insert_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		'CREATE TRIGGER %s AFTER UPDATE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.update_entity()',  
		'update_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		'CREATE TRIGGER %s AFTER UPDATE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.delete_entity()',  
		'delete_entity_' || table_name, schema_name, table_name);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM pg_catalog.pg_trigger;

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
	INSERT INTO model.entity(id, schema_name, table_name, userid) VALUES (NEW.id, TG_TABLE_SCHEMA, TG_TABLE_NAME, user);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.update_entity() RETURNS TRIGGER AS
$$
BEGIN
	UPDATE model.entity SET updated = NOW() WHERE id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.delete_entity() RETURNS TRIGGER AS
$$
BEGIN
	UPDATE model.entity SET deleted = NOW() WHERE id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.add_audit(table_name regclass) RETURNS void AS
$$
BEGIN
	PERFORM format ('CREATE TRIGGER %s AFTER INSERT ON %s FOR EACH ROW EXECUTE PROCEDURE insert_entity()',  'insert_entity_' || table_name::text, table_name);
END;
$$ LANGUAGE plpgsql;


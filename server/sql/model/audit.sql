CREATE SCHEMA IF NOT EXISTS audit;

CREATE OR REPLACE FUNCTION audit.insert_entity() RETURNS TRIGGER AS
$insert_entity$
BEGIN
	IF TG_TABLE_NAME = 'entity' THEN
		RETURN NEW;
	END IF;
	EXECUTE format($XXX$
		INSERT INTO "%s".entity(id, table_name, userid) 
			VALUES ('%s', '%s', '%s')
		 ON CONFLICT(id) DO 
			UPDATE SET updated = NOW() WHERE entity.id = '%s'
		;
	$XXX$, TG_TABLE_SCHEMA, NEW.id, TG_TABLE_NAME, USER, NEW.id);
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
		RETURN OLD;
	END IF;
	EXECUTE format($$
		UPDATE %s.entity SET deleted = NOW() WHERE id = '%s';
	$$, TG_TABLE_SCHEMA, OLD.id);
	RETURN NEW;
END;
$delete_entity$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.add_audit(schema_name TEXT, table_name TEXT) RETURNS SETOF TEXT AS
$add_audit$
BEGIN
	PERFORM * FROM pg_catalog.pg_tables WHERE tablename = 'entity' AND schemaname = schema_name;
	IF NOT FOUND THEN
		EXECUTE format($xxx$
			CREATE TABLE IF NOT EXISTS %s.entity(
				id uuid PRIMARY KEY,
				table_name TEXT NOT NULL,
				created TIMESTAMPTZ DEFAULT now() NOT NULL,
				updated TIMESTAMPTZ,
				deleted TIMESTAMPTZ,
				userid TEXT NOT NULL
			); $xxx$, schema_name);
	END IF;

	EXECUTE format (
		 $$ CREATE TRIGGER %s AFTER INSERT ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.insert_entity() $$, 
		'trigger_insert_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		$$ CREATE TRIGGER %s AFTER UPDATE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.update_entity() $$,  
		'trigger_update_entity_' || table_name, schema_name, table_name);
	EXECUTE format (
		$$ CREATE TRIGGER %s AFTER DELETE ON %s.%s FOR EACH ROW EXECUTE PROCEDURE audit.delete_entity() $$,  
		'trigger_delete_entity_' || table_name, schema_name, table_name);
	RETURN NEXT 'trigger_insert_entity_' || table_name;
	RETURN NEXT 'trigger_update_entity_' || table_name;
	RETURN NEXT 'trigger_delete_entity_' || table_name;
END;
$add_audit$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit.remove_audit(schema_name TEXT, table_name TEXT) RETURNS SETOF TEXT AS
$delete_audit$
BEGIN
	EXECUTE format($$ DROP TRIGGER "%s" ON %s.%s; $$, 'trigger_insert_entity_' || table_name, schema_name, table_name);
	EXECUTE format($$ DROP TRIGGER "%s" ON %s.%s; $$, 'trigger_update_entity_' || table_name, schema_name, table_name);
	EXECUTE format($$ DROP TRIGGER "%s" ON %s.%s; $$, 'trigger_delete_entity_' || table_name, schema_name, table_name);
END;
$delete_audit$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION audit.remove_audit(schema_name TEXT) RETURNS SETOF TEXT AS
$remove_audit$
SELECT audit.remove_audit(schemaname, tablename) FROM (
	SELECT schemaname, tablename
		FROM pg_catalog.pg_tables
			LEFT JOIN pg_catalog.pg_trigger ON tgname = 'trigger_insert_entity_' || tablename
		WHERE schemaname = schema_name AND tgname IS NOT NULL
) t;
$remove_audit$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION audit.get_type(_id uuid) RETURNS text AS
$get_type$
DECLARE 
	_table_name TEXT;
BEGIN
	SELECT table_name 
		INTO _table_name 
		FROM model.entity 
		WHERE entity.id = _id;
	IF NOT FOUND THEN 
		RAISE EXCEPTION 'No entity found for %', _id;
	END IF;
	RETURN _table_name;
END;
$get_type$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION audit.get_name(_id uuid) RETURNS text AS
$get_name$
DECLARE
	_table_name TEXT;
	ret TEXT;
BEGIN	
	IF _id IS NULL THEN
		RETURN NULL;
	END IF;
	
	SELECT audit.get_type(_id) INTO _table_name;

	EXECUTE format($$
		SELECT name FROM model."%s" WHERE id = '%s' LIMIT 1
	$$, _table_name, _id)  INTO ret;
	RETURN ret;
END;
$get_name$ LANGUAGE plpgsql IMMUTABLE;
-- SELECT a,b FROM audit.get_name('c17b4725-51c3-4f72-8b15-e14af04b656f'::uuid) AS (a text, b text)

CREATE OR REPLACE FUNCTION model.convert_incoming_to_model_trigger() RETURNS trigger AS
$convert_incoming_to_model_trigger$
BEGIN

	PERFORM  * FROM api.warnings WHERE id = NEW.id;
	IF FOUND THEN
		RETURN NEW;
	END IF;
	PERFORM model.convert_incoming_to_model(NEW.id);
	RETURN NEW;
END;
$convert_incoming_to_model_trigger$ LANGUAGE PLPGSQL;

DROP TRIGGER IF EXISTS model_update ON api.snapshot;

CREATE TRIGGER model_update
    AFTER INSERT OR UPDATE ON api.snapshot
    FOR EACH ROW
    EXECUTE PROCEDURE model.convert_incoming_to_model_trigger();
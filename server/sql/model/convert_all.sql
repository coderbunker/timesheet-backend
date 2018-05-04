CREATE OR REPLACE FUNCTION model.convert_all() RETURNS SETOF model.entry AS
$$
    SELECT model.convert_incoming_to_model((s.id)::TEXT) FROM (
        SELECT id FROM api.snapshot
    ) s;
$$ LANGUAGE SQL;
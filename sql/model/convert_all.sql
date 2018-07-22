CREATE OR REPLACE FUNCTION model.convert_all() RETURNS SETOF uuid AS
$$
    SELECT model.convert_incoming_to_model((s.id)::TEXT) FROM (
        SELECT id FROM api.snapshot
    ) s;
$$ LANGUAGE SQL;
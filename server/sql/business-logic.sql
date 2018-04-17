CREATE OR REPLACE FUNCTION compute_gross(text, float, INTERVAL) RETURNS NUMERIC AS
$$
DECLARE 
	project_rate float;
BEGIN
	RETURN round((project_rate * (extract(hours FROM $3) + extract(minutes FROM $3) / 60))::numeric, 2);
END 
$$ LANGUAGE plpgsql IMMUTABLE;
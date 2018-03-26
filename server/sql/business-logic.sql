CREATE OR REPLACE FUNCTION compute_gross(text, float, INTERVAL) RETURNS NUMERIC AS
$$
DECLARE 
	project_rate float;
BEGIN
	if($1 = '1F7TYweE11OqGyZZRZYmmMMHLDokhfyPHQMkdZKzV6Qs') THEN
		project_rate = 0;
	ELSE
		project_rate = $2;
	END IF;
	RETURN round((project_rate * (extract(hours FROM $3) + extract(minutes FROM $3) / 60))::numeric, 2);
END 
$$ LANGUAGE plpgsql IMMUTABLE;
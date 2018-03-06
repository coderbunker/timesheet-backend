CREATE OR REPLACE FUNCTION incoming.convert_to_interval(text)
  RETURNS INTERVAL AS
$func$
BEGIN
  -- covers 00:00 TO xx:00 hours
  RETURN $1::INTERVAL;
EXCEPTION WHEN OTHERS THEN
  BEGIN
  -- covers 00:00 AM|PM
  	RETURN $1::time::INTERVAL;
  EXCEPTION WHEN OTHERS THEN
   	RETURN NULL;  -- NULL for other invalid input
  END;
END
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.convert_stop(interval, interval)
  RETURNS INTERVAL AS
$func$
BEGIN
 	IF extract(epoch FROM $2 - $1) < 0 THEN 
 		RETURN ($2 + INTERVAL '24 hours');
 	END IF;
	RETURN $2;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.extract_rate(text)
  RETURNS float AS
$func$
DECLARE	
	return_value FLOAT;
BEGIN
	SELECT ((regexp_matches($1, '[0-9]*\.?[0-9]'))[1])::float INTO return_value;
	RETURN return_value;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

SELECT incoming.extract_rate('600');

CREATE OR REPLACE FUNCTION incoming.extract_currency(text)
  RETURNS text AS
$func$
DECLARE	
	return_value text;
BEGIN
	SELECT (regexp_matches($1, '[^0-9\.]'))[1] INTO return_value;
	RETURN return_value;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.extract_freelancer(json)
  RETURNS text AS
$func$
DECLARE	
	return_value text;
BEGIN
	SELECT COALESCE($1->>'resource', COALESCE($1->>'freelancer', 'MISSINGKEY')) INTO return_value;
    RETURN return_value;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

SELECT INTERVAL '24:00' - INTERVAL '22:00'

SELECT incoming.convert_stop(INTERVAL '15:00', INTERVAL '00:30') 
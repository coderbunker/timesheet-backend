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
  RETURNS NUMERIC AS
$func$
DECLARE
	return_value NUMERIC;
BEGIN
	SELECT safe_cast(regexp_replace($1, '[^0-9\-\.]', '', 'g'), NULL::NUMERIC) INTO return_value;
	RETURN return_value;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.extract_currency(text)
  RETURNS text AS
$func$
DECLARE
	return_value text;
BEGIN
	SELECT (regexp_matches($1, '([^0-9\.]*)'))[1] INTO return_value;
	RETURN return_value;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION incoming.extract_percentage(text)
  RETURNS NUMERIC AS
$func$
DECLARE
	return_value NUMERIC;
BEGIN 
	SELECT safe_cast(((regexp_matches($1, '([0-9]+)%?'))[1]), NULL::NUMERIC)
		INTO return_value;
	IF return_value IS NOT NULL THEN
		SELECT return_value / 100.0 INTO return_value;
	END IF;
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

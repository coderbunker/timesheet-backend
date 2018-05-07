CREATE OR REPLACE FUNCTION model.symbol_to_currency(text)
  RETURNS text AS
$func$
DECLARE
	_code TEXT;
BEGIN
	IF $1 IS NULL THEN
		RETURN NULL;
	END IF; 

	SELECT code INTO _code FROM model.iso4217 WHERE code = $1;
	IF FOUND THEN
		RETURN $1;
	END IF;
	IF $1 = '¥' THEN
		RETURN 'RMB';
	END IF;

	IF $1 = '$' THEN
		-- one project in Singapore but paid in USD!
		RETURN 'USD';
	END IF;

	RAISE EXCEPTION 'No such currency symbol recognized %', $1;
END;
$func$  LANGUAGE plpgsql IMMUTABLE;

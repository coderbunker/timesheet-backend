CREATE OR REPLACE FUNCTION create_email_domain(schemaname TEXT, typename TEXT) RETURNS void AS
$create_email_domain$
DECLARE
	domain_exists boolean;
BEGIN
	SELECT TRUE INTO domain_exists
		FROM pg_catalog.pg_type JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_type.typnamespace 
		WHERE 
		nspname = schemaname AND
		typname = typename
		;
	
	IF NOT domain_exists THEN
		EXECUTE format($$
		CREATE DOMAIN %s.%s AS citext
		  CHECK ( value ~ '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$' );
		$$, schemaname, typname);
	END IF;
END;
$create_email_domain$ LANGUAGE plpgsql;

SELECT create_email_domain('model', 'email');
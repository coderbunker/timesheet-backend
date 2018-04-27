CREATE OR REPLACE FUNCTION create_email_domain(schemaname TEXT, typename TEXT) RETURNS TEXT AS
$create_email_domain$
DECLARE
	domain_exists boolean;
 	regexp TEXT;
	create_query TEXT;
BEGIN
	PERFORM *
		FROM pg_catalog.pg_type JOIN pg_catalog.pg_namespace ON pg_namespace.oid = pg_type.typnamespace 
		WHERE 
		nspname = schemaname AND
		typname = typename
		;


	
	IF NOT FOUND THEN
		SELECT format($$
			CREATE DOMAIN %s.%s AS citext
			  CHECK ( value ~  '^[a-zA-Z0-9.!#$%%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
			$$, schemaname, typename)
			INTO create_query
		;
		
		EXECUTE create_query;
		RETURN create_query;
	END IF;
	RETURN NULL::TEXT;
END;
$create_email_domain$ LANGUAGE plpgsql;

SELECT create_email_domain('model', 'email');



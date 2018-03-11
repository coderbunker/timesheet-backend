CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS postgraphql;
DROP MATERIALIZED VIEW IF EXISTS postgraphql.people_month_gross;
CREATE MATERIALIZED VIEW postgraphql.people_month_gross AS
SELECT 
	encode(digest(email, 'md5'), 'hex') AS id, 
	gross_overall,
	billable_month 
	FROM report.gross_people 
	WHERE 
		gross_overall IS NOT NULL AND
		gross_overall > 0 AND
		email IS NOT NULL
	ORDER BY gross_overall desc;

SELECT * FROM postgraphql.people_month_gross;
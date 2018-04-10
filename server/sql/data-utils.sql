-- https://gist.github.com/ryandotsmith/4602274
DROP AGGREGATE IF EXISTS array_accum(anyarray);
CREATE AGGREGATE array_accum (anyarray)
(
    sfunc = array_cat,
    stype = anyarray,
    initcond = '{}'
);

CREATE OR REPLACE FUNCTION trim_array(json) RETURNS text[] AS
$$
	SELECT array_agg(trim(altname)) FROM json_array_elements_text($1) AS altname
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION trim_array(jsonb) RETURNS text[] AS
$$
	SELECT array_agg(trim(altname)) FROM jsonb_array_elements_text($1) AS altname
$$ LANGUAGE SQL IMMUTABLE;
-- SELECT trim_array('["Sam Evers", " SamE"]') -> { "Sam Evers", "SamE" }

CREATE OR REPLACE FUNCTION to_month_label(timestamptz) RETURNS text AS
$$
	SELECT (extract(year FROM $1)*100 + extract(MONTH FROM $1))::text
$$ LANGUAGE SQL immutable;

-- TESTCASE
-- SELECT to_month_label(now());

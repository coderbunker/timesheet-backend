CREATE SCHEMA IF NOT EXISTS utils;

-- https://gist.github.com/ryandotsmith/4602274
DROP AGGREGATE IF EXISTS array_accum(anyarray);
CREATE AGGREGATE array_accum (anyarray)
(
    sfunc = array_cat,
    stype = anyarray,
    initcond = '{}'
);

CREATE OR REPLACE FUNCTION utils.trim_array(json) RETURNS text[] AS
$$
	SELECT array_agg(trim(altname)) FROM json_array_elements_text($1) AS altname
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION utils.trim_array(jsonb) RETURNS text[] AS
$$
	SELECT array_agg(trim(altname)) FROM jsonb_array_elements_text($1) AS altname
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION utils.to_month_label(timestamptz) RETURNS text AS
$$
	SELECT (extract(year FROM $1)*100 + extract(MONTH FROM $1))::text
$$ LANGUAGE SQL immutable;

CREATE OR REPLACE FUNCTION utils.to_numeric_hours(i INTERVAL) RETURNS NUMERIC AS
$$
	SELECT (EXTRACT(HOUR FROM i) + (EXTRACT(MINUTE FROM i)/60))::NUMERIC
$$ LANGUAGE SQL IMMUTABLE;
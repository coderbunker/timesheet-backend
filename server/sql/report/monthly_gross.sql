CREATE OR REPLACE VIEW report.monthly_gross AS
	WITH extracted AS (
		SELECT 
			EXTRACT(YEAR FROM stop_datetime)::INTEGER AS entry_year,
			EXTRACT(MONTH FROM stop_datetime)::INTEGER AS entry_month,
			timesheet.*
			FROM model.timesheet
	) SELECT 
		entry_year,
		entry_month,
		(entry_year::text || to_char(entry_month, 'fm00'))::NUMERIC AS label,
		to_char(to_timestamp(entry_month::text, 'MM'), 'TMMon') AS entry_month_name,
		round(sum(total), 2) AS total,
		currency,
		vendor_name
	FROM extracted
	GROUP BY entry_year, entry_month, vendor_name, currency
	ORDER BY entry_year, entry_month ASC
	;

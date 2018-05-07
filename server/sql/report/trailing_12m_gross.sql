CREATE OR REPLACE VIEW report.trailing_12m_gross AS
	WITH extracted AS (
		SELECT 
			EXTRACT(YEAR FROM stop_datetime)::INTEGER AS entry_year,
			EXTRACT(MONTH FROM stop_datetime)::INTEGER AS entry_month,
			timesheet.*
			FROM model.timesheet
			WHERE stop_datetime > (now() - '12 months'::INTERVAL)
	) SELECT 
		entry_year,
		entry_month,
		to_char(to_timestamp(entry_month::text, 'MM'), 'TMMon') AS entry_month_name,
		round(sum(total), 2) AS total,
		currency,
		vendor_name
	FROM extracted
	WHERE entry_year < extract(YEAR FROM now()) OR entry_month < extract(month FROM now())
	GROUP BY entry_year, entry_month, vendor_name, currency
	ORDER BY entry_year, entry_month ASC
	;
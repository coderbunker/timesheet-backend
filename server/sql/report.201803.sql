SELECT
	*
FROM
	report.gross_people
WHERE
	billable_month =(
		SELECT
			to_month_label(
				NOW()
			) AS month_label
	)
ORDER BY
	gross_overall DESC;

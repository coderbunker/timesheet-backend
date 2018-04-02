SELECT
	*
FROM
	report.gross_people
-- LEFT JOIN LATERAL to_month_label(NOW()) AS month_label ON TRUE
WHERE
	billable_month = '201803'
ORDER BY
	gross_overall DESC;


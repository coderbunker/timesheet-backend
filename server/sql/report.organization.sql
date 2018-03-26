CREATE OR REPLACE VIEW report.organization AS
	SELECT
			'Coderbunker Shanghai' AS orgname,
			min(summary_person.first_entry) AS since,
			age(now(), min(summary_person.first_entry))::text AS activity,
			count(DISTINCT summary_person.email) AS people_count,
			(SELECT count(DISTINCT gross_project.project_id) FROM report.gross_project) AS project_count,
			(SELECT count(*) FROM incoming.account WHERE status = 'Ongoing') AS ongoing_project_count,
			(SELECT sum(gross_overall) FROM report.gross_project) AS total_gross,
			sum(total_hours)/168 AS total_eng_months
		FROM report.summary_person
		;
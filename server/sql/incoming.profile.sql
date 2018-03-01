CREATE VIEW incoming.profile_raw AS
	SELECT
		json_array_elements((doc#>'{data}')::json) AS freelancer
	FROM
		incoming.snapshot
	WHERE doc->>'apptype' = 'Slides' AND doc->>'category' = 'Freelancers'
	;
		
CREATE VIEW incoming.profile AS
	SELECT 
		freelancer->>'fullname' AS fullname,
		freelancer->>'email' AS email,
		freelancer->>'github' AS github,
		freelancer->>'wechat' AS wechat,
		freelancer->>'status' AS status,
		freelancer->>'rate' AS rate,
		freelancer->>'keywords' AS keywords
	FROM 
		incoming.profile_raw;
		
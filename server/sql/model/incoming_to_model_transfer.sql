CREATE OR REPLACE FUNCTION model.customer_to_account_deposit(
	_source_id uuid, 
	_target_id uuid, 
	_amount NUMERIC, 
	_currency TEXT, 
	_recorded TIMESTAMPTZ
) RETURNS SETOF model.ledger AS
$bootstrap$
BEGIN
	PERFORM * 
		FROM model.ledger 
		WHERE 
			source_id = _source_id AND 
			target_id = _target_id AND 
			amount = _amount AND
			currency = _currency AND 
			recorded = _recorded
	;
	IF FOUND THEN
		RETURN next NULL;
	ELSE 
		RETURN QUERY INSERT INTO model.ledger(source_id, target_id, amount, currency, recorded) 
			VALUES(NULL, _source_id, _amount, _currency, _recorded) RETURNING *;
		RETURN QUERY INSERT INTO model.ledger(source_id, target_id, amount, currency, recorded) 
			VALUES(_source_id, _target_id, _amount, _currency, _recorded) RETURNING *;
	END IF;
END;
$bootstrap$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION model.import_transfer() RETURNS SETOF model.ledger AS
$import_transfer$
	SELECT * FROM (
		SELECT model.customer_to_account_deposit(
			customer_id, 
			account_id, 
			amount, 
			model.symbol_to_currency(currency), 
			transfer_datetime)
		FROM incoming.transfer
			INNER JOIN model.project ON (properties->>'docid' = project_id)
			INNER JOIN model.account ON (account_id = account.id)
	) AS b;
$import_transfer$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION model.freelancer_payout(
	_source_id uuid, 
	_target_id uuid, 
	_amount NUMERIC, 
	_currency TEXT, 
	_recorded TIMESTAMPTZ
) RETURNS SETOF model.ledger AS
$create_transaction$
DECLARE
	ledger model.ledger;
	host uuid;
	vendor uuid;
	deduction NUMERIC;
	remaining NUMERIC;
BEGIN
	PERFORM * 
		FROM model.ledger 
		WHERE 
			source_id = _source_id AND 
			target_id = _target_id AND 
			amount = _amount AND
			currency = _currency AND 
			recorded = _recorded
	;
	IF FOUND THEN
		RETURN;
	END IF;

-- TODO: allow negative balance? borrowing?
--	PERFORM * FROM model.balance 
--		WHERE id = _source_id AND 
--			account_balance >= _amount;
--	IF NOT FOUND THEN 
--		RAISE EXCEPTION 'Insufficient found in % (%) for % % -> % (%)', 
--			audit.get_name(_source_id), _source_id, 
--			_amount, _currency, 
--			audit.get_name(_target_id), _target_id;
--	END IF;

	SELECT vendor_id INTO vendor FROM model.account WHERE id = _source_id;

	remaining := _amount;
	IF vendor IS NOT NULL THEN
		deduction := _amount*0.1;
		RETURN QUERY INSERT INTO model."ledger"(source_id, target_id, amount, currency, recorded)
			VALUES(_source_id, vendor, deduction, _currency, _recorded) 
			ON CONFLICT(source_id, target_id, amount,  recorded) DO NOTHING
			RETURNING *
			;
		remaining := remaining - deduction;
	END IF;
	
	SELECT host_id INTO host FROM model.account WHERE id = _source_id;
	IF host IS NOT NULL THEN 
		deduction := _amount*0.13;
		RETURN QUERY INSERT INTO model."ledger"(source_id, target_id, amount, currency, recorded)
			VALUES(_source_id, host, deduction, _currency, _recorded) 
			ON CONFLICT(source_id, target_id, amount, recorded) DO NOTHING
			RETURNING *
			;
		remaining := remaining - deduction;
	ELSE
		RAISE NOTICE 'No host found';
	END IF; 
	
	RETURN QUERY INSERT INTO model."ledger"(source_id, target_id, amount, currency, recorded)
		VALUES(_source_id, _target_id, remaining, _currency, _recorded) 
		ON CONFLICT(source_id, target_id, amount, recorded) DO NOTHING
		RETURNING *
		;	
	
	RETURN;
END;
$create_transaction$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION model.process_payouts() RETURNS SETOF model.ledger AS
$process_payouts$
	 SELECT model.freelancer_payout(t.account_id, t.person_id, t.total, t.currency, t.recorded) FROM (
		WITH person_entry AS (
			SELECT 
				EXTRACT(YEAR FROM stop_datetime)::INTEGER year_group, 
				EXTRACT(MONTH FROM stop_datetime)::INTEGER AS month_group, 
				person_id,
				account_id,
				total, 
				currency 
			FROM model.timesheet
		), current_month AS(
			SELECT 
				EXTRACT(YEAR FROM NOW())::INTEGER current_year, 
				EXTRACT(MONTH FROM NOW())::INTEGER AS current_month
		)
		SELECT 
			person_id, 
			account_id,
			sum(total) AS total,
			currency,
			format('%s-%s-01', year_group, month_group)::TIMESTAMPTZ AS recorded
		FROM person_entry, current_month
		WHERE 
			year_group <= current_year AND 
			month_group < current_month
		GROUP BY person_id, account_id, year_group, month_group, currency
		ORDER BY year_group, month_group
		) t
	WHERE total > 0
	;
$process_payouts$ LANGUAGE SQL;
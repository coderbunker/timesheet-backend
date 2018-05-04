-- schema
\ir incoming/schema.sql

-- conversion specific
\ir incoming/conversion.sql

-- derived entities
\ir incoming/account.sql
\ir incoming/project.sql
\ir incoming/profile.sql
\ir incoming/entry.sql
\ir incoming/people.sql
\ir incoming/transfer.sql
\ir incoming/waveapps.sql

-- with calendar inputs
\ir incoming/entry_calendar.sql
\ir incoming/entry_union.sql

-- reports
\ir incoming/warnings.sql

-- import facilities
\ir incoming/update_from_server.sql
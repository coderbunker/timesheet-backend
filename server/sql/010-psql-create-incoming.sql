-- schema
\ir incoming/schema.sql

-- reusable function logic
\ir safe_cast.sql
\ir utils.sql
\ir business-logic.sql
\ir incoming/conversion.sql

-- snapshot api and store
\ir api.snapshot.sql
\ir incoming/snapshot.sql

-- derived entities
\ir incoming/account.sql
\ir incoming/project.sql
\ir incoming/profile.sql
\ir incoming/entry.sql
\ir incoming/people.sql
\ir incoming/transfer.sql

-- with calendar inputs
\ir incoming/entry_calendar.sql
\ir incoming/entry_union.sql

-- reports
\ir incoming/warnings.sql

-- import facilities
\ir incoming/update_from_server.sql


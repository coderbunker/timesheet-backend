-- reusable function logic
\ir business-logic.sql
\ir data-utils.sql
\ir incoming.conversion.sql

-- snapshot api and store
\ir api.snapshot.sql
\ir incoming.snapshot.sql

-- derived entities
\ir incoming.account.sql
\ir incoming.project.sql
\ir incoming.profile.sql
\ir incoming.entry.sql
\ir incoming.people.sql

-- reports
\ir report.people.sql
\ir report.organization.sql
\ir incoming.warnings.sql

-- postgraphql interface
\ir postgraphql.sql

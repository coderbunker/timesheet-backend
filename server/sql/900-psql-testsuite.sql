\ir 003-psql-create-extensions-localhost.sql
\ir test/schema.sql
\ir test/api.sql
\ir test/test.utils.sql
\ir test/scenario1.sql
\ir test/utils.sql
\ir test/incoming.sql
\ir test/model.sql
\ir test/audit.sql
\ir test/ledger.sql
\ir test/report.sql

SELECT * FROM runtests('test'::name)
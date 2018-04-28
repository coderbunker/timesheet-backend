\ir test/test.utils.sql
\ir test/utils.sql
\ir test/incoming.sql
\ir test/model.sql
\ir test/audit.sql
\ir test/ledger.sql
\ir test/report.sql

SELECT * FROM runtests('test'::name)

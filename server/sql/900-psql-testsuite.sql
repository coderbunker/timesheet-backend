\ir test/utils.sql
\ir test/incoming.sql
\ir test/model.sql

SELECT * FROM runtests('test'::name)

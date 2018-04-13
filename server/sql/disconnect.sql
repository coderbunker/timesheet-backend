SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'heroku-timesheet-20180410'
  AND pid <> pg_backend_pid()
  ;

  
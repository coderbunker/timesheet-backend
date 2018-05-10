# Connect DBeaver to Heroku Postgres Database

## Install PostgreSQL and DBeaver

1. Download and install PostgreSQL according to https://www.postgresql.org/download/
2. Download and install DBeaver according to https://dbeaver.io/download/

## Get Heroku Credientials

1. Ask Karl or Ricky to be invited as a collaborator of Heroku Coderbunker team.
2. Navigate to Team: Coderbunker, Apps: coderbunker-timesheet, and Add-ons: Heroku Postgres.
3. Go to Settings to find Database Credentials there.

## Connect DBeaver to Heroku Postgres Database

1. On DBeaver, open the <b>New Connection Wizard</b>.
2. Select PostgreSQL as Connection Type and click Next.
3. Fill out the Host, Database, Port, User, and Password fields with the Credentials and click Next.
4. Go to <b>SSL Tab</b>, check <b>Enable SSL</b>, and set the <b>SSL Factory</b> to <b>org.postgresql.ssl.NonValidatingFactory</b>.
5. Click <b>Test Connection</b> and it should return "Success".
6. Click Finish and you are all set

## Reference

http://thebar.cc/connecting-dbeaver-to-a-heroku-postgres-database/?

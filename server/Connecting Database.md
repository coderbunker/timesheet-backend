# Connecting DBeaver to Heroku Postgres Database

## Installing PostgreSQL and DBeaver

1. Download and install PostgreSQL according to https://www.postgresql.org/download/
2. Download and install DBeaver according to https://dbeaver.io/download/

## Getting Heroku Credientials

1. Ask Karl or Ricky to be invited as a collaborator of Heroku Coderbunker team.
2. Navigate to Team: Coderbunker, Apps: coderbunker-timesheet, and Add-ons: Heroku Postgres.
3. Go to Settings to find Database Credentials there.

## Connecting DBeaver to Heroku Postgres Database

1. On DBeaver, open the <b> New Connection Wizard </b>
2. Select PostgreSQL as Connection Type and click Next
3. Fill out the Host, Database, Port, User, and Password fields with the Credentials and click Next
4. Go to SSL Tab, check Enable SSL, and set the SSL Factory to <b> org.postgresql.ssl.NonValidatingFactory </b>.
5. Click <b> Test Connection </b> and it should return "Success"
6. Click Finish and you are done.

## Reference

Connecting DBeaver to a Heroku Postgres Database: http://thebar.cc/connecting-dbeaver-to-a-heroku-postgres-database/?nsukey=eUuvKrydSfqqpIchC17FTZsHuwjrK88%2FCYkPP5L0ER4RZUTwHvo%2BZAaV0JZmZ9PArHhyHtMzAmdL%2FbJXtuYDE2IaG2durzZABaETlJEbKPUKX6DlrJCg8p4A3oQemAReMNTXnbLEeZNp7IgzsCojM%2FAauqydrIfq%2BB6WNLB7zAO1gAClP6c1OnP1H0l0CmGv%2BpSmryw%2FkOK7uL14WM23eQ%3D%3D

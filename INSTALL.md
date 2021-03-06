# Running the system locally

## setup NodeJS latest LTS

* Install NVM: https://github.com/creationix/nvm

```bash
nvm install --lts
```

## install

```bash
npm install
npm start
```

install PostgreSQL extensions:

```bash
pip install pgxnclient
pgxn install pgtap
```

create schema of DB

```bash
createdb timesheet
./setup.sh timesheet
```

this will also run the test suite.

## run test suite on changes

```bash
brew install fswatch
./watch-test.sh timesheet
```

## Exposing local as a web service

Use http://ngrok.io

## Testing

Sample file:

```JSON
{
  "id": "1234",
  "doc": {
    "apptype": "Spreadsheet",
    "category": "Timesheet"
   },
  "apikey": "STRING_CONFIGURED_IN_ENV"
}
```

post to the API:

```bash
curl --verbose -X POST "http://localhost:3000/gsuite/snapshot" -H "Content-Type: application/json" -d @samples/coderbunker-intranet-timesheet.json
```

should return:

```JSON
[{"snapshot_json":[]}]
```

## backing up database

database:

```bash
pg_dump -N postgraphql_watch -O -s postgresql://localhost/timesheet > sql/timesheet.sql
```

## deploying to Heroku

Because Heroku requires the app to be in the root, we use subtree to push:

```bash
git subtree push --prefix server heroku master
```

Creating/updating schema on Heroku instance:

```bash
psql -v "ON_ERROR_STOP=1" -b -1 -e -f sql/PSQL.sql `heroku pg:credentials:url | tail -1`
```

Restarting the dyno (to load changes to the database for example)

```bash
heroku restart -a coderbunker-timesheet
```

## data transfer to/from heroku

Pushing the local database:

```bash
heroku pg:push timesheet postgresql-rigid-65921 --app coderbunker-timesheet
```

Pulling the Heroku database locally and making a copy before changing the pulled version
(adjust date):

```bash
heroku pg:pull postgresql-rigid-65921 heroku-timesheet --app coderbunker-timesheet
psql -c 'CREATE DATABASE "heroku-timesheet-20180416" TEMPLATE "heroku-timesheet";' postgres
```

## Containerization

- Build Image: `docker build -t timesheet-backend .`

- Run Container: `docker run -p 3000:3000 -e DATABASE_URL=postgres://docker.for.mac.localhost/DATABASE_NAME timesheet-backend`

## Manage Domain

### CNAME Setup for Heroku app

1. Get CNAME from heroku:   `heroku domains -a coderbunker-timesheet`

2. add CNAME to google domains

    | NAME   |      TYPE      |  TTL  |                  DATA                 |
    |--------|:--------------:|------:|--------------------------------------:|
    | data   |      CNAME     |  1h   |   data.coderbunker.com.herokudns.com. |


### SSL Setup

Enable SSL automatically managed by heroku.

## troubleshooting

want to push an amended history with subtree push? sadly, does not support push.

create a local branch and force push that first:

```
git subtree split --prefix server -b backup-branch
git push -f heroku backup-branch:master
```

should now be back to normal...

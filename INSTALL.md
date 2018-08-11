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
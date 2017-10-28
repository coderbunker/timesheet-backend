# timesheet-backend

Timesheet Datawarehouse backend

## How this repo was initialized

```
npm init
npm install --save postgraphql
```

## Environment initialized

```
brew install postgresql
pg_ctl -D /usr/local/var/postgres start
```

## Database setup

```
createdb timesheet
psql timesheet -f timesheet.sql
```
## Running

Running the API from the command-line (replace rngadam-mac.local by your hostname):

```
./node_modules/.bin/postgraphql --disable-default-mutations --dynamic-json --schema dw --watch -c postgres://localhost/timesheet --cors --host rngadam-mac.local
```

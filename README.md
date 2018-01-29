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

## To extract Data fro google

Create a private key “Client_Secret.json” following the procedure in  GoogleAPI.txt

python spreadsheet.py 

## Database setup

```
createdb timesheet
psql timesheet -f import.sql  → imports timesheet.json in the DB
psql timesheet -f timesheet.sql → creates views
```
## Running

Running the API from the command-line (replace rngadam-mac.local by your hostname):

```
./node_modules/.bin/postgraphql --disable-default-mutations --dynamic-json --schema dw --watch -c postgres://localhost/timesheet --cors --host rngadam-mac.local
```

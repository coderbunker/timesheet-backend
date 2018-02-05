# timesheet-backend

Timesheet Datawarehouse backend


## How this repo was initialized

```
npm init
npm install --save postgraphile
```

## Environment initialized

```
brew install postgresql
pg_ctl -D /usr/local/var/postgres start
``` 

## To extract Data from Google

Create a private key “Client_Secret.json” following the procedure in  GoogleAPI.txt
```
python spreadsheet.py 
``` 

## Database setup

```
createdb timesheet
psql timesheet -f import.sql  → imports timesheet.json in the DB
psql timesheet -f timesheet.sql → creates views
```
## Running


### Start the database server

    pg_ctl -D sqldatabase/ start

### Start postgraphil server 

    postgraphil -c $USER:localhost:5432/timesheet -s timedata

## Manually test the servers

### Manually query the database

    psql timesheet $USER
    select * from timedata.entries;

### Manually query postgraphile server

    alias ql='curl -X POST -H "Content-Type: application/graphql" -d'
    ql '{ allEntries { edges { node { projectName, resource } }}}' http://localhost:5000/graphql
# timesheet-backend

Timesheet Datawarehouse backend


## How this repo was initialized

```
npm init
npm install --save postgraphile
```

## Environment initialo ized

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
sudo -u postgres psql -c "CREATE USER $USER SUPERUSER;" --> create a user in PostgreSQL so you can connect
createdb timesheet
psql timesheet -f create_dw.sql  →  creates tables, views and functions to connect to postgraphile
python copy_files.py
```
## Running


### Start the database server

    pg_ctl -D sqldatabase/ start

### Start postgraphile server 

    postgraphile -c $USER:localhost:5432/timesheet -s timedata -o

## Manually test the servers

### Manually query the database

    psql timesheet $USER
    select * from timedata.entries;

### Manually query postgraphile server

    alias ql='curl -X POST -H "Content-Type: application/graphql" -d'
    ql '{ allEntries { edges { node { projectName, resource } }}}'
    ql '{ allEntries(condition: {resource: "Ricky"}) { edges { node {
	      projectName, resource }}}}' 
    http://localhost:5000/graphql

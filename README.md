# timesheet-backend

Timesheet Datawarehouse backend


## How to install the dependencies

```
npm install
```

## Running the database server

```
brew install postgresql
pg_ctl -D /usr/local/var/postgres start
``` 

## To extract Data from Google

Create a private key “Client_Secret.json” following the procedure in GoogleAPI.txt
```
python spreadsheet.py 
``` 

This step can be skipped if you have the .csv file for testing data.

## Database setup

```
sudo -u postgres psql -c "CREATE USER $USER SUPERUSER;" --> create a user in PostgreSQL so you can connect
createdb timesheet
psql timesheet -f create_dw.sql  →  creates tables, views and functions to connect to postgraphile
python copy_files.py
```

You might not need ```sudo -u postgres``` if you're running the postgresql database process as your own user. 

## Running


### Start postgraphil server 

    node_modules/.bin/postgraphil -c $USER:localhost:5432/timesheet -s timedata

## Manually test the servers

### Manually query the database

    psql timesheet $USER
    select * from timedata.entries;

### Manually query postgraphile server

    alias ql='curl -X POST -H "Content-Type: application/graphql" -d'
    ql '{ allEntries { edges { node { projectName, resource } }}}' http://localhost:5000/graphql


## Manage Domain


### CNAME Setup for Heroku app

1. Get CNAME from heroku:   `heroku domains -a coderbunker-timesheet`

2. add CNAME to google domains

    | NAME   |      TYPE      |  TTL  |                  DATA                 |
    |--------|:--------------:|------:|--------------------------------------:|t
    | data   |      CNAME     |  1h   |   data.coderbunker.com.herokudns.com. | 
    

### SSL Setup

Enable SSL automatically managed by heroku.


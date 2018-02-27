# Integration with Google Spreadsheet

## setup NodeJS latest LTS

* Install NVM: https://github.com/creationix/nvm

```bash
nvm install --lts
```

## install

```bash
npm install
node app.js
```

restore schema of DB

```bash
sudo su postgres
createdb timesheet
psql timesheet -f sql/timesheet.sql
```

## Apache hook

Apache config:

```text
<Location "/spreadsheet">
  ProxyPass "http://localhost:3000/spreadsheet"
</Location>
```

restart:

```bash
systemctl restart apache2
```

## Setup

creates two routes:

* /spreadsheet/snapshot/SPREADSHEET_ID
* /spreadsheet/change/SPREADSHEET_ID

## Testing

```bash
curl -X POST http://localhost:3000/spreadsheet/snapshot/1234 -H "Content-Type: application/json" -d @coderbunker-intranet-timesheet.json
```

## backing up database

database:

```bash
pg_dump -N postgraphql_watch -O -s postgresql://localhost/timesheet > sql/timesheet.sql
```

## deploying to Heroku

Because Heroku requires the app to be in the root, we use subtree to push:

```
git subtree push --prefix server heroku master
```

Pushing the local database:

```
heroku pg:push timesheet postgresql-rigid-65921 --app coderbunker-timesheet
```
# Heroku Deployment

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

## deploying to Heroku

Creating/updating schema on Heroku instance:

```bash
psql -v "ON_ERROR_STOP=1" -b -1 -e -f sql/PSQL.sql `heroku pg:credentials:url | tail -1`
```

Restarting the dyno (to load changes to the database for example)

```bash
heroku restart -a coderbunker-timesheet
```

## data transfer to/from heroku database

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

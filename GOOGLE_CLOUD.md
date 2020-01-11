# Google Cloud Deployment

## Create instances

* Postgresql
* NodeJS

## Postgresql on Google Cloud Platform



* create user postgraphql and set password
* create database timesheet
* grant IP access to the NodeJS public IP (created below)

Note that watch cannot work because cannot CREATE TRIGGER:

https://cloud.google.com/sql/docs/postgres/features

```text
Unsupported: Any features that require SUPERUSER privileges
```

## NodeJS


## test database access

```bash
psql postgres://postgraphql:5lZCuNwog0YwXqQd7g1v@35.187.155.121/timesheet
```

## running example

* install and checkout source code

## Configure Apache for proxying Postgraphile connections

Enable proxy modules:

```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
```

setup endpoints:

```text
<Location "/graphql">
  ProxyPass "http://localhost:5000/graphql"
</Location>
<Location "/graphiql">
  ProxyPass "http://localhost:5000/graphiql"
</Location>
<Location "/_postgraphql">
  ProxyPass "http://localhost:5000/_postgraphql"
</Location>
<Location "/__schema">
  ProxyPass "http://localhost:5000/__schema"
</Location>
```

restart:

```bash
systemctl restart apache2
```

Running:

```bash
node_modules/.bin/postgraphile -c postgres://postgraphql:$POSTGRAPHQL_PASSWORD@35.187.155.
121/timesheet -s postgraphql
```

## Testing

```psql
create database timesheet;
\c timesheet
create user postgraphql;
alter user postgraphql with password 'helloworld';
```

reconnect as user:

```psql
create schema postgraphql;
create view postgraphql.messages as SELECT 1 as id, 'hello world'::text AS message;
```

use text query:

```graphql
{
  allMessages {
    edges {
      node {
        id
        message
      }
    }
  }
}
```

output should be:

```
{
  "data": {
    "allMessages": {
      "edges": [
        {
          "node": {
            "id": 1,
            "message": "hello world"
          }
        }
      ]
    }
  }
}
```
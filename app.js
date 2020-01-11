require('dotenv').config()

const express = require('express')
const Router = require('express-promise-router')
const bodyParser = require('body-parser')
const { postgraphile } = require("postgraphile");
const cookieParser = require('cookie-parser');
const { Pool } = require('pg')

function createQuery(dburl) {
    console.log('connecting to DATABASE_URL=%s', dburl);

    const pool = new Pool({
        connectionString: dburl
    });

    return function(text, params) {
        pool.query(text, params);
    }
}

function postgraphileDefaultConfig(config) {
    config = config || {};
    return Object.assign({
        dynamicJson: true,
        disableDefaultMutations: false,
        graphiql: true,
        watchPg: true,
        enableCors: true,
        extendedErrors: ['hint', 'detail', 'errcode']
    }, config);
}

function validateApiKey(apikey) {
    return function(req, res, next) {
        function err(e) {
            res.writeHead(400);
            res.end(JSON.stringify({error: e}));
        }
        if(req.originalUrl.match(/internal/)) {
            if(!((req.body && req.body.apikey === apikey) || req.cookies.apikey === apikey)) {
                return err(`invalid api key for ${req.originalUrl}`);
            }
        }
        next();
    }
}

// create a new express-promise-router
// this has the same API as the normal express router except
// it allows you to use async functions as route handlers
function createRouter(router, query) {
    router.post('/snapshot', async (req, res) => {
      function err(e) {
        res.writeHead(400);
        res.end(JSON.stringify({error: e}));
      }

      if(!req.body.id) {
        return err("id is not defined in body")
      }
      if(!req.body.doc) {
        return err("doc is not defined in body")
      }
      const { rows, fields } = await query(
          `SELECT api.snapshot_json($1, $2::json)`,
          [
            req.body.id,
            JSON.stringify(req.body.doc)
          ])
      var json = JSON.stringify(rows[0].snapshot_json);
      res.writeHead(200, {'content-type':'application/json', 'content-length': Buffer.byteLength(json)});
      res.end(json);
    });

    return router;
}

function registerEndpoint(app, schema, endpoints) {
    if(!endpoints) {
        endpoints = {
            graphqlRoute: `/${schema}/graphql`,
            graphiqlRoute: `/${schema}/graphiql`
        }
    }

    app.use(postgraphile(
        process.env.DATABASE_URL || "postgres://localhost/heroku-timesheet",
        schema,
        postgraphileDefaultConfig(endpoints)
    ));
}

function createServer(app, router, mountPoint, apikey, port) {
    app.use(mountPoint, router);
    app.use(cookieParser());
    app.use(validateApiKey(apikey));

    registerEndpoint(app, 'postgraphql', {});
    registerEndpoint(app, 'internal');

    // parse application/x-www-form-urlencoded
    app.use(bodyParser.urlencoded({
        extended: false
    }))

    // parse application/json
    app.use(bodyParser.json({
        limit: "5mb"
    }))

    app.use(express.static(__dirname + '/public'));

    var server = app.listen(port, function() {
        console.log(JSON.stringify(server.address()))
        const host = server.address().address;
        const port = server.address().port;
        console.log('timesheet app listening at http://%s:%s', host, port);
    });

    return server;
}

if (require.main === module) {
    const query = createQuery(process.env.DATABASE_URL);
    const router = createRouter(new Router(), query);
    const server = createServer(express(), router, '/gsuite', process.env.APIKEY, process.env.PORT);
} else {
    module.exports = { createServer, createRouter, createQuery };
}
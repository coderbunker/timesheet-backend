require('dotenv').config()

const express = require('express')
const mountRoutes = require('./routes')
const bodyParser = require('body-parser')
const { postgraphile } = require("postgraphile");

const app = express()

app.use(postgraphile(
    process.env.DATABASE_URL || "postgres://localhost/heroku-timesheet",
    "postgraphql",
    {
        dynamicJson: true,
        disableDefaultMutations: true,
        graphiql: true,
        watchPg: true,
        enableCors: true
    }
));

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({
    extended: false
}))

// parse application/json
app.use(bodyParser.json({
    limit: "5mb"
}))

app.use(express.static(__dirname + '/public'));

mountRoutes(app)

console.log('port: %s', process.env.PORT)
var server = app.listen(process.env.PORT, () => {
    console.log(JSON.stringify(server.address()))
    const host = server.address().address;
    const port = server.address().port;
    console.log('timesheet app listening at http://%s:%s', host, port);
});

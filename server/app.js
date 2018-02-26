require('dotenv').config()

const express = require('express')
const mountRoutes = require('./routes')
const bodyParser = require('body-parser')

const app = express()

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({
    extended: false
}))

// parse application/json
app.use(bodyParser.json({
    limit: "5mb"
}))

mountRoutes(app)

console.log('port: %s', process.env.PORT)
var server = app.listen(process.env.PORT, () => {
    const host = server.address().address;
    const port = server.address().port;
    console.log('Example app listening at http://%s:%s', host, port);
});

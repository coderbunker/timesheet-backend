const express = require('express');
const { postgraphile } = require('postgraphile');

const app = express();
const port = 4000;

app.use(
	postgraphile( 'postgres://localhost:5432/timesheet' )
);

app.listen(port, 
	console.log('express app listening on port' + " " + port)
);
const { Pool } = require('pg')

console.log('connecting to DATABASE_URL=%s', process.env.DATABASE_URL)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

module.exports = {
  query: (text, params) => pool.query(text, params)
}
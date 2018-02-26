const { Pool } = require('pg')
const pool = new Pool()

module.exports = {
  connectionString: process.env.DATABASE_URL,
  ssl: true,
  query: (text, params) => pool.query(text, params)
}
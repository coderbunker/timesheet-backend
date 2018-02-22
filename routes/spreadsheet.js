const Router = require('express-promise-router')

const db = require('../db')

// create a new express-promise-router
// this has the same API as the normal express router except
// it allows you to use async functions as route handlers
const router = new Router()

// export our router to be mounted by the parent application
module.exports = router

router.post('/snapshot/:id', async (req, res) => {
  const { id } = req.params
  console.log(JSON.stringify(req.body));
  const { rows } = await db.query(
      'INSERT INTO incoming.data(data, id) VALUES($1, $2) ON CONFLICT(id) DO UPDATE SET data = EXCLUDED.data WHERE data.id = EXCLUDED.id',
      [JSON.stringify(req.body), req.params.id])
  res.end('OK');
})

router.post('/change/:id', async (req, res) => {
  const { id } = req.params
  const { rows } = await db.query(
      'INSERT INTO incoming.changes(data,id) VALUES($1, $2)',
      [JSON.stringify(req.body), req.params.id])
  res.end('OK');
})
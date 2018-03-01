const Router = require('express-promise-router')

const db = require('../db')

// create a new express-promise-router
// this has the same API as the normal express router except
// it allows you to use async functions as route handlers
const router = new Router()

// export our router to be mounted by the parent application
module.exports = router

router.post('/snapshot', async (req, res) => {
  console.log(JSON.stringify(req.body));
  const { rows } = await db.query(
      `INSERT INTO incoming.snapshot(id, doc)
        VALUES($1, $2)
        ON CONFLICT(id) DO
          UPDATE SET data = EXCLUDED.data WHERE snapshot.id = EXCLUDED.id`,
      [
        req.body.id,
        JSON.stringify(req.body.doc)
      ])
  res.end('OK');
});
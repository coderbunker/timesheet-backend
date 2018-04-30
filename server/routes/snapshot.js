const Router = require('express-promise-router')

const db = require('../db')

// create a new express-promise-router
// this has the same API as the normal express router except
// it allows you to use async functions as route handlers
const router = new Router()

// export our router to be mounted by the parent application
module.exports = router

router.post('/snapshot', async (req, res) => {
  function err(e) {
    res.writeHead(400);
    res.end(JSON.stringify({error: e}));
  }
  if(req.body.apikey !== process.env.APIKEY) {
    return err("invalid api key")
  }
  if(!req.body.id) {
    return err("id is not defined in body")
  }
  if(!req.body.doc) {
    return err("doc is not defined in body")
  }

  const { rows, fields } = await db.query(
      `SELECT api.snapshot_json($1, $2::json)`,
      [
        req.body.id,
        JSON.stringify(req.body.doc)
      ])
  var json = JSON.stringify(rows);
  res.writeHead(200, {'content-type':'application/json', 'content-length': Buffer.byteLength(json)});
  res.end(json);
});
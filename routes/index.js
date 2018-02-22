const spreadsheet = require('./spreadsheet')

module.exports = (app) => {
  app.use('/spreadsheet', spreadsheet)
}
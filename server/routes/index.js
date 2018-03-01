const snapshot = require('./snapshot')

module.exports = (app) => {
  app.use('/gsuite', snapshot)
}
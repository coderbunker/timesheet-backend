const timesheet = require('./timesheet')
const profile = require('./profile')

module.exports = (app) => {
  app.use('/timesheet', timesheet)
  app.use('/profile', profile)

}
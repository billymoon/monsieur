exec = require('child_process').exec

module.exports = (app)->
  if app.program.exec
    app.server.use (req, res, next) ->
      exec app.program.exec, next

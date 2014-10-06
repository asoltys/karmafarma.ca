db = require('../redis')
config = require('../config')
sendgrid = require('sendgrid')(config.sendgrid_user, config.sendgrid_password)

module.exports =
  show: (req, res) ->
    db.hgetall("farm:#{decodeURIComponent(req.params.email)}", (err, obj) ->
      res.write(JSON.stringify(obj))
      res.end()
    )

  create: (req, res) ->
    user = 
      email: req.body.email
      phone: req.body.phone
      address: req.body.address
      notes: req.body.notes

    key = "farm:#{req.body.email}"
    db.hmset(key, user, ->
      res.render('welcome', 
        layout: 'mail'
        user: user
        js: (-> global.js)
        css: (-> global.css)
        (err, html) ->
          throw err if err
          email = new sendgrid.Email(
            to: [req.body.email, 'sea.green@gmail.com']
            from: 'sea.green@gmail.com'
            subject: 'Welcome to Karma Farma'
            html: html
          )

          sendgrid.send(email)
      )
    )

db = require('../redis')
config = require('../config')
sendgrid = require('sendgrid')(config.sendgrid_user, config.sendgrid_password)

module.exports =
  create: (req, res) ->
    userkey = "farm:#{req.body.email}"
    db.hmset(userkey,
      email: req.body.email,
      phone: req.body.phone,
      address: req.body.address
    )

    res.render('welcome', 
      layout: 'mail',
      js: (-> global.js), 
      css: (-> global.css),
      (err, html) ->
        throw err if err
        email = new sendgrid.Email(
          to: req.body.email
          from: 'sea.green@gmail.com'
          subject: 'Welcome to Karma Farma'
          html: html
        )

        sendgrid.send(email)
    )

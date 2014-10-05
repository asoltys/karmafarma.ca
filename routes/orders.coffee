db = require('../redis')
config = require('../config')
sendgrid = require('sendgrid')(config.sendgrid_user, config.sendgrid_password)

module.exports =
  create: (req, res) ->
    db.set("order:#{req.body.email}:#{req.body.week}", req.body.order, ->
      res.end()
    )

    res.render('order', 
      layout: 'mail',
      order: JSON.parse(req.body.order),
      js: (-> global.js), 
      css: (-> global.css),
      (err, html) ->

        email = new sendgrid.Email(
          to: req.body.email
          from: 'sea.green@gmail.com'
          subject: 'Karma Farma Order'
          html: html
        )

        sendgrid.send(email)
    )

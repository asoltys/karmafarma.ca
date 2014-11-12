fs = require('fs')
express = require('express')
path = require('path')
engines = require('consolidate')
request = require('request')
db = require('./redis')

app = express()
app.enable('trust proxy')
app.engine('html', require('mmm').__express)
app.set('view engine', 'html')
app.set('views', __dirname + '/views')
app.use(express.static(__dirname + '/public'))
app.use(require('connect-assets')(src: 'public'))
app.use(express.bodyParser())
app.use(express.cookieParser())
app.use(app.router)

do fetchRates = ->
  request("https://api.bitcoinaverage.com/exchanges/all", (error, response, body) ->
    try 
      require('util').isDate(JSON.parse(body).timestamp)
      file = 'public/js/rates.json'
      stream = fs.createWriteStream(file)
      fs.truncate(file, 0, ->
        stream.write(body)
      )
  )
  setTimeout(fetchRates, 120000)

orders = require('./routes/orders')
users = require('./routes/users')

routes =
  "/about": 'about'
  "/contact": 'contact',
  "/register": 'register'


for route, view of routes
  ((route, view) ->
    app.get(route, (req, res) ->
      res.render(view,
        js: (-> global.js),
        css: (-> global.css),
        layout: 'layout',
      )
    )
  )(route, view)

app.get('/', (req, res) ->
  db.keys('farm:*', (err, result) ->
    users = 10 - result.length
    res.render('index',
      users: users
      register: req.query.register?
      js: (-> global.js)
      css: (-> global.css)
      layout: 'layout'
    )
  )
)

app.get('/users/:email', users.show)
app.post('/users', users.create)
app.post('/orders', orders.create)

app.use((err, req, res, next) ->
  res.status(500)
  console.log(err)
  res.end()
)

app.listen(3003)

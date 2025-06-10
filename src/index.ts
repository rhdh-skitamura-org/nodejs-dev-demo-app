const express = require('express')
const app = express()
const router = express.Router()

app.use(express.json())
app.use(express.urlencoded({ extended: false }))

app.use((req, res, next) => {
  const started = process.hrtime.bigint()
  res.on('finish', () => {
    const diffMs =
      Number(process.hrtime.bigint() - started) / 1e6
    console.log(
      `${new Date().toISOString()} ` +
      `${req.ip} ${req.method} ${req.originalUrl} ` +
      `${res.statusCode} - ${diffMs.toFixed(1)} ms`
    )
  })
  next()
})


router.get('/', function (req, res) {
  res.send('Hello World!!!!!!!!!!')
})

app.use('/', router)

const listenPort = process.env.PORT || 3000;

app.listen(listenPort)
console.log(`Running at port ${listenPort}`)

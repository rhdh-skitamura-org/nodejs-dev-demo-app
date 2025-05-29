const express = require('express')
const app = express()
const router = express.Router()

app.use(express.json())
app.use(express.urlencoded({ extended: false }))

router.get('/', function (req, res) {
  res.send('Hello World!')
})

app.use('/', router)

const listenPort = process.env.PORT || 3000;

app.listen(listenPort)
console.log(`Running at port ${listenPort}`)

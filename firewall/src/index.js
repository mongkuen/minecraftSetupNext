const express = require('express')
const axios = require('axios')
const requestIp = require('request-ip')

const PORT = 8080
const HOST = '0.0.0.0'

const app = express()
app.use(express.urlencoded({ extended: true }))
app.use(requestIp.mw())
app.set('trust proxy', true)

app.get('/minecraft', (req, res) => {
  res.send(`<form action="/minecraft" method="POST"><label for="password">Register: </label><input type="password" name="password" id="password"/><button type="submit">Submit</button></form>`)
})

app.post('/minecraft', (req, res) => {
  if (req.body.password === process.env.PASSWORD) {
    axios({
      method: 'post',
      url: 'https://api.digitalocean.com/v2/firewalls/b02ddf82-c6f0-4f09-8a27-d91f4394af79/rules',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.AUTH}`
      },
      data: {
        inbound_rules: [
          {
            protocol: "udp",
            ports: "53",
            sources: {
              addresses: [
                req.clientIp
              ]
            }
          }
        ]
      }
    })
      .then((doRes) => {
        res.redirect('/minecraft/success')
      })
      .catch((err) => {
        res.redirect('/minecraft/failure')
      })
  } else {
    res.redirect('/minecraft/failure')
  }
})

app.get('/minecraft/success', (req, res) => {
  res.send('Done!')
})

app.get('/minecraft/failure', (req, res) => {
  res.send('<button onclick="history.back()">Retry</button>')
})

app.listen(PORT, HOST)
console.log(`Running on http://${HOST}:${PORT}`)

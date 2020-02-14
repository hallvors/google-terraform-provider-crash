'use strict';
const express = require('express');
const exphbs = require('express-handlebars');

const env = require('./config/environment');
const cronConfig = require('./config/cron_token');
const app = express();

app.engine('.hbs', exphbs({extname: '.hbs'}));
app.set('views', './client/views/')
app.set('view engine', '.hbs');

// GCP health check will query this URL
app.get('/gcp_healthcheck', (req, res, next) => {
  res.status(200);
  res.end();
});

app.get('/tools/crontest', (req, res, next) => {
  if (req.get('token') !== cronConfig.accessToken) {
    res.status(401);
    return next(new Error('Forbidden'));
  }
  res.send('OK');
});

app.get('/', (req, res, next) => {
  const conf = env.nconf.get('site');
  res.render('index', {
    conf: JSON.stringify(conf, null, 2),
  })
});

const server = require('http').createServer();
server.on('request', app);

server.listen(env.port, () => {
  console.log(`[ready] http://localhost:${env.port}`);
});

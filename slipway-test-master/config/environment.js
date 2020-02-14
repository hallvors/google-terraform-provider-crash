const port = process.env.PORT || 4466;
const env = process.env.NODE_ENV || 'development';
const nconf = require('nconf');

nconf.env('__').argv();
nconf.add('overrides', {type: 'file', file: `${__dirname}/overrides.json`});
nconf.add('environment', {type: 'file', file: `${__dirname}/${env}.json`});
nconf.add('defaults', {type: 'file', file: `${__dirname}/defaults.json`});

module.exports = {port, env, nconf};

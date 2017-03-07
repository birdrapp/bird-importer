const winston = require('winston');

const logger = new (winston.Logger)({
  transports: [
    new (winston.transports.File)({
      filename: 'audit.log',
      json: false,
      level: 'info'
    })
  ]
});

module.exports = logger;

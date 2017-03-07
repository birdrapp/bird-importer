const async = require('async');
const csv = require('fast-csv');
const fs = require('fs');
const logger = require('./logger');
const request = require('request');

const titleCase = (s) => s.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());
let total = 0;
let count = 0;

let queue = async.queue((bird, callback) => {
  request.post({
    url: 'https://api.birdr.co.uk/v1/birds',
    json: bird
  }, (err, res, body) => {
    count += 1;
    console.log('Processed %d of %d birds', count, total);
    if (err) return console.error(err);

    if (res.statusCode === 201) {
      logger.info('%s created successfully.', bird.commonName);
    } else {
      logger.error('%s failed to create.', bird.commonName);
    }

    callback();
  });
}, 5);

const stream = fs.createReadStream("BirdLife_Checklist_Version_9.csv");
csv
  .fromStream(stream, { headers: true })
  .validate((data) => data['BirdLife taxonomic treatment'] === 'R') // we only want recognised species
  .on("data", function (data) {
    let birdParams = {
      commonName: data['Common name'],
      scientificName: data['Scientific name'],
      order: titleCase(data['Order']),
      familyName: data['Family name'],
      family: data['Family'],
      alternativeNames: data['Alternative common names'].split(', ').filter(String)
    };

    queue.push(birdParams);
    total += 1;
  })
  .on("end", () => console.log('%d birds queued for processing.', total));

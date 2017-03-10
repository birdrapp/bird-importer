const async = require('async');
const colors = require('colors');
const csv = require('fast-csv');
const fs = require('fs');
const request = require('request');

const titleCase = (s) => s.replace(/\w\S*/g, (txt) => txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase());

let queue = async.queue((bird, callback) => {
  request.post({
    url: 'https://api.birdr.co.uk/v1/birds',
    json: bird
  }, (err, res, body) => {
    if (err) return console.error(err);

    if (res.statusCode !== 201) {
      console.error('✘'.red + ' %s', bird.scientificName);
    } else {
      console.info('✔'.green + ' %s', bird.scientificName);
    }

    callback();
  });
});

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
      family: data['Family']
    };

    queue.push(birdParams);
  })
  .on('end', () => console.log('Importing...'))

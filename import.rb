require 'csv'
require 'rest-client'
require 'colorize'

species_id = nil
species_name = nil
birdr_url = 'https://api.birdr.co.uk/birds'

CSV.foreach 'lists/clements.csv', headers: true do |row|
  species_name = row['English name'] unless row['English name'].nil?

  # Polytypic groups aren't actually species - so skip them
  next if row['Category'] == 'group (polytypic)'

  bird_params = {
    commonName: species_name,
    scientificName: row['Scientific name'],
    order: row['Order'],
    family: row['Family'].split('(')[0].rstrip,
    familyName: row['Family'].split('(')[1].gsub(')', ''),
    sort: row['sort v2016']
  }

  bird_params['speciesId'] = species_id unless row['Category'] == 'species'

  response = RestClient.post birdr_url, bird_params.to_json, content_type: :json, accept: :json

  if response.code == 201
    body = JSON.parse(response.body)
    species_id = body['id'] if row['Category'] == 'species'
    puts '✔'.green + ' ' + body['commonName']
  else
    puts '✘'.red + ' ' + row['Scientific name']
    exit 1
  end
end

require 'csv'
require 'colorize'
require 'rest-client'

BIRDR_HOST = 'https://api.birdr.co.uk'
LIST_ID = '0b108dc4-0829-11e7-ade0-9b5afe6cac4b'
post_url = "#{BIRDR_HOST}/lists/#{LIST_ID}/birds"

def lookup_url(scientific_name)
  "#{BIRDR_HOST}/birds?scientificName=#{scientific_name}"
end

def lookup_bird(scientific_name)
  url = "#{BIRDR_HOST}/birds?scientificName=#{scientific_name}"

  response = RestClient.get url
  body = JSON.parse(response)
  bird = body['data'].first
  return bird['id'] unless bird.nil?
end

def add_bird_to_list(params)
  url = "#{BIRDR_HOST}/lists/#{LIST_ID}/birds"

  begin
      response = RestClient.post url, params.to_json, content_type: :json, accept: :json
      response.code
    rescue RestClient::ExceptionWithResponse => e
      e.response.code
    end
end

CSV.foreach 'lists/the-british-list.csv', headers: true do |row|
  scientific_name = row['Scientific name']
  bird_id = lookup_bird(scientific_name)

  if bird_id.nil?
    puts "Could not find bird #{scientific_name}. Please enter the ID"
    bird_id = gets.strip
  end

  params = {
    birdId: bird_id,
    sort: row['Sort'],
    localName: row['Vernacular name']
  }

  code = add_bird_to_list params

  if code == 204
    puts '✔'.green + ' ' + row['Vernacular name']
  elsif code == 409
    puts '-'.light_blue + ' ' + row['Vernacular name'] + ' already exists in the list'
  else
    puts '✘'.red + ' ' + scientific_name
  end
end

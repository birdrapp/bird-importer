require 'csv'
require 'nokogiri'

def parse_language_line(line, offset)
  line.last(line.length - 4).compact
end

# Parses the multi-language IOC file (must be converted to .csv)
def parse_multilang_file(filename)
  line_number = 1
  languages = []
  species = {}
  current_offset = 0
  current_species = nil
  current_species_translations = {}

  CSV.foreach(filename, "r") do |line|
    if line_number > 1
      next unless line[1].nil?
      next unless line[2].nil?
    end

    if line_number < 4
      languages[line_number - 1] = []
      parse_language_line(line, line_number - 1).each do |language|
        languages[line_number - 1] << {
          column: line.index(language),
          name: language
        }
      end
    elsif not line[3].nil? and current_species != line[3]
      # store current species if exists
      if not current_species.nil?
        species[current_species] = current_species_translations
      end
      # new species
      current_offset = 0
      current_species = line[3]
      current_species_translations = {}

      languages[current_offset].each do |language|
        current_species_translations[language[:name].downcase.to_sym] = line[language[:column]]
      end
      current_offset += 1
    else
      # add more languages
      languages[current_offset].each do |language|
        current_species_translations[language[:name].downcase.to_sym] = line[language[:column]]
      end
      current_offset += 1
    end
    line_number += 1
  end

  species[current_species] = current_species_translations
  species
end

def parse_xml_file(filename)
  sort = 1
  ioc = File.open(filename) { |f| Nokogiri::XML(f) }
  birds = []

  ioc.xpath("//order").each do |order_elem|
    order = order_elem.xpath('latin_name').text

    order_elem.xpath('family').each do |family_elem|

      latin_family = family_elem.xpath('latin_name').text
      english_family = family_elem.xpath('english_name').text

      family_elem.xpath('genus').each do |genus_elem|

        genus = genus_elem.xpath('latin_name').text

        genus_elem.xpath('species').each do |species_elem|

          species = species_elem.xpath('latin_name').text
          english_name = species_elem.xpath('english_name').text

          bird_params = {
            common_name: english_name,
            scientific_name: "#{genus} #{species}",
            order: order,
            scientific_family_name: latin_family,
            common_family_name: english_family,
            sort_position: sort,
            species_id: nil
          }

          birds << bird_params
          species_id = sort
          sort += 1

          species_elem.xpath('subspecies').each do |subspecies_elem|

            subspecies = subspecies_elem.xpath('latin_name').text
            bird_params = {
              common_name: english_name,
              scientific_name: "#{genus} #{species} #{subspecies}",
              order: order,
              scientific_family_name: latin_family,
              common_family_name: english_family,
              sort_position: sort,
              species_id: species_id
            }

            birds << bird_params

            sort += 1
          end # subspecies

        end # species

      end # genus

    end # family

  end # order

  birds
end

translations = parse_multilang_file("lists/multi-lang.csv")
birds = parse_xml_file("lists/master_ioc-names_xml.xml")

birds.each do |b|
  name = b[:scientific_name].split(' ').first(2).join(' ')
  # t = translations[name]
  if translations[name].nil?
    p "Skipping #{b}"
    next
  end
  b.merge! translations[name]
end

CSV.open("output/ioc-with-translations.csv", "w") do |csv|
  csv << [:id] + birds.first.keys
  birds.each_with_index do |hash, index|
    hash.each do |key, value|
      if value.nil? and not key == :species_id
        hash[key] = hash[:common_name]
      end
    end
    csv << [index+1] + hash.values
  end
end

p birds.first(2)


require 'csv'

line_number = 1
@languages = []
@species = []

def parse_language_line(line, offset)
  @languages[offset] = []
  temp_languages = line.last(line.length - 4).compact
  temp_languages.each do |language|
    @languages[offset] << {
      column: line.index(language),
      name: language
    }
  end
end

current_offset = 0
current_species = nil
current_species_translations = []

CSV.foreach("multi-lang.csv", "r") do |line|
  if line_number > 1
    next unless line[1].nil?
    next unless line[2].nil?
  end

  if line_number < 4
    parse_language_line line, line_number - 1
  elsif not line[3].nil? and current_species != line[3]
    # store current species if exists
    if not current_species.nil?
      @species << current_species_translations
    end
    # new species
    current_offset = 0
    current_species = line[3]
    current_species_translations = [line[3]]

    @languages[current_offset].each do |language|
      current_species_translations << line[language[:column]]
    end
    current_offset += 1
  else
    # add more languages
    @languages[current_offset].each do |language|
      current_species_translations << line[language[:column]]
    end
    current_offset += 1
  end
  line_number += 1
end

CSV.open("translations.csv", "w") do |csv|
  csv << (['Scientific'] + @languages.flatten.map {|l| l[:name]})
  @species.each {|s| csv << s }
end

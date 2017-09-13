require 'nokogiri'
require 'csv'

sort = 1
ioc = File.open("lists/master_ioc-names_xml.xml") { |f| Nokogiri::XML(f) }


def import_bird(file, params)
  file << params

  params[5]
end

CSV.open("ioc.csv", "w") do |f|
  f << ["common_name", "scientific_name", "order", "scientific_family_name", "common_family_name", "sort_position", "species_id"]
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

          bird_params = [
            english_name,
            "#{genus} #{species}",
            order,
            latin_family,
            english_family,
            sort,
            nil
          ]

          species_id = import_bird(f, bird_params)
          sort += 1

          species_elem.xpath('subspecies').each do |subspecies_elem|

            subspecies = subspecies_elem.xpath('latin_name').text
            bird_params = [
              english_name,
              "#{genus} #{species} #{subspecies}",
              order,
              latin_family,
              english_family,
              sort,
              species_id
            ]

            import_bird(f, bird_params)

            sort += 1
          end # subspecies

        end # species

      end # genus

    end # family

  end # csv

end # order

# encoding: UTF-8

require 'rubygems'
require 'neography'
require 'httparty'

@neo = Neography::Rest.new

#hack to create the indexes
new_node = Neography::Node.create("name" => "temp")
new_node.add_to_index("legislator_index", "id", 1)
new_node.add_to_index("congress_index", "id", 1)
#clean slate
@neo.execute_query "START r=rel(*) DELETE r;"
@neo.execute_query "START n=node(*) DELETE n;"

def getOrCreateLegislator(legislator_data)
  node = Neography::Node.find("legislator_index", "id", legislator_data["person"]["id"])
  if node.nil?
    node = Neography::Node.create("id" => legislator_data["person"]["id"], "name" => legislator_data["person"]["name"])
    for congress_number in legislator_data["congress_numbers"]
      Neography::Relationship.create("MEMBER_OF_CONGRESS", node, getOrCreateCongress(congress_number))
    end
    node.add_to_index("legislator_index", "id", legislator_data["person"]["id"])
  end
  return node
end

def getOrCreateCongress(congress_number)
  node = Neography::Node.find("congress_index", "number", congress_number)
  if node.nil?
    node = Neography::Node.create("number" => congress_number, "name" => congress_number)
    node.add_to_index("congress_index", "number", congress_number)
  end
  return node
end


response = HTTParty.get("http://www.govtrack.us/api/v2/role?current=true")

response["objects"].each do |legislator_data|
  legislator = getOrCreateLegislator(legislator_data)
  puts legislator
end


require "rest_client"
require "json"
require "peach"
require "csv"

def getRelationship(u,targ)
  friends_uri = "#{u}/friends/#{targ}"
   
   url = "#{$host}#{friends_uri}?access_token=#{$accesstoken}"
   cont = true
   begin
     response  = RestClient.get url
   rescue => e
     cont = false
   end
   if cont
      tmp = JSON.parse(response)
      return (tmp["data"].size > 0 )
   else
     return false
   end
end

def getProfileInfo(u,fld)
  usr_uri = "#{u}"
   
   url = "#{$host}#{usr_uri}?fields=#{fld}&access_token=#{$accesstoken}"
   cont = true
   begin
     response  = RestClient.get url
   rescue => e
     cont = false
   end
   if cont
     response = JSON.parse(response)
     return response[fld]
   else
     return false
   end
end

def pullProfilePic()
end

def persistRelationship(id1 , id2 , un1 , un2)
  host = "http://localhost:9200/"
  index = "facebookesp"
  type = "relationship"
  type_all = "relationship_all"
  
  id = ""
  if id1.to_i < id2.to_i
    id = "#{id1}#{id2}"
  else
    id = "#{id2}#{id1}"
  end
  id_all = "#{id1}#{id2}"

  json = {"target"=>un1,"friend"=>un2}
  json = json.to_json
  
  #post to condensed relationship type
  url = "#{host}#{index}/#{type}/#{id}"
  response = RestClient.post url , json, :content_type => :json, :accept => :json
  
  #post to relationship_all type
  url = "#{host}#{index}/#{type_all}/#{id_all}"
  response = RestClient.post url , json, :content_type => :json, :accept => :json
  
  #post opposite relationship to relationship_all 
  json = {"target"=>un2,"friend"=>un1}
  json = json.to_json
  id_all = "#{id2}#{id1}"

  url = "#{host}#{index}/#{type_all}/#{id_all}"
  response = RestClient.post url , json, :content_type => :json, :accept => :json
  
end


#TODO move to ARGV
$accesstoken = ARGV[1]
$host = "https://graph.facebook.com/v1.0/"


# STEP 1a: READ CSV FILE.  Check each row for fb_un.  IF un exists, check if fb_id field is set, if not, query graph to get id
users = []
allusers = []
puts "Step 1a >>> Read input file and add all Facebook ID #s where the fb_id field is missing or nil"  
CSV.foreach(ARGV[0], :headers => true , :converters => []) do |csv_obj|
csv_obj = csv_obj.to_hash
   if(csv_obj["fb_un"].nil? == false)
      if(csv_obj.has_key?("fb_id") == false || ( csv_obj.has_key?("fb_id") && (csv_obj["fb_id"].nil? || csv_obj["fb_id"] == false )) )
          puts "Missing FB ID for #{csv_obj["fb_un"]}"
          csv_obj["fb_id"] = getProfileInfo(csv_obj["fb_un"],"id");
      end
      users << csv_obj
   end
end

# STEP 1b:  Output new CSV to input_expand.csv.
puts "Step 1b >>> Output new inputfile to input_expanded.csv"  
CSV.open("input_expanded.csv","w") do |csv|
  first = true
  users.each do |x|
      if(first)
        first = false
        csv << x.keys
      end
      csv << x.values
  end
end

#STEP 2: Determine  all relationships between users.
puts "Step 2 >>> Determine Relationships and store in array.  Post to ElasticSearch"
relations = []
users.each_with_index do | u , k1|
    users.each_with_index do |t , k2|
      if(k2 > k1)
        if(getRelationship(u["fb_id"],t["fb_id"]))
          puts "Relationship found! #{u["fb_un"]} - #{t["fb_un"]}"
          persistRelationship(u["fb_id"],t["fb_id"] ,u["fb_un"],t["fb_un"])
          relations << { "targ" => u , "frnd" => t }
        end
      end
    end
end

puts "Step 3 >>> Persist relationships to output csv.  Each friendship saved once"
CSV.open("relationships.csv","w") do |csv|
  csv << ["targ","frnd"]
  relations.each do |x|
    csv << [x["targ"]["fb_un"],x["frnd"]["fb_un"]]
  end
end

puts "Script complete."
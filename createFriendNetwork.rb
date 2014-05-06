
require "rest_client"
require "json"
require "peach"

def getFriends(u)
  friends_uri = "#{u}/friends"
   
   url = "#{$host}#{friends_uri}?limit=10000&access_token=#{$accesstoken}&fields=username"
   cont = true
   puts url
   begin
     response  = RestClient.get url
   rescue => e
     cont = false
   end
   if cont
     return response
   else
     return false
   end
end

def getProfileInfo(u,fld)
  usr_uri = "#{u}"
   
   url = "#{$host}#{usr_uri}?limit=10000&access_token=#{$accesstoken}"
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

def persistRelationship(id1 , id2 , un1 , un2)
  host = "http://localhost:9200/"
  index = "facebookesp"
  type = "relationship"
  
  id = ""
  if id1.to_i < id2.to_i
    id = "#{id1}#{id2}"
  else
    id = "#{id2}#{id1}"
  end

  url = "#{host}#{index}/#{type}/#{id}"
  json = {"target"=>un1,"friend"=>un2}
  json = json.to_json
  
  response = RestClient.post url , json, :content_type => :json, :accept => :json
end

def persistFriends(id , json)
  host = "http://localhost:9200/"
  index = "facebookesp"
  type = "friends"
  
  url = "#{host}#{index}/#{type}/#{id}"
  
  response = RestClient.post url , json, :content_type => :json, :accept => :json
end

def checkRelationship(un,id)
  host = "http://localhost:9200/"
  index = "facebookesp"
  type = "friends"
  uri = "_search"
  
  url = "#{host}#{index}/#{type}/#{uri}"
  json = '{
  "fields" : [],
    "query": {
      "bool": {
        "must": [
          {
            "nested": {
              "path": "friends.data",
              "query": {
                "bool": {
                  "must": [
                    {
                      "term": {
                        "data.id": "'+id+'"
                      }
                    }
                  ]
                }
              }
            }
          }
        ]
      }
    },
    "size": 100
  }'
  puts json
  response = RestClient.post url , json, :content_type => :json, :accept => :json
  puts response
  respArr = JSON.parse(response)
  
  if(respArr["hits"]["total"]>0)
    respArr["hits"]["hits"].each do |x|
      persistRelationship(id, x["_id"] , un , getProfileInfo(x["_id"],"username"))
    end
  end
end

#TODO move to ARGV
$accesstoken = "CAACEdEose0cBAGZCSezbYeEGXh0uCPBbOymOLT6RkmC8dWDQefEEOGsCBN5S482ZCZAZCN9uPxNkzodQ5TVUKH69Mr72YQBkuE3vfIPLzl3nl2rLEw3mZBA4EgGIIK7lYETKRDcpDgMEJ4zJZBOXAsOGQkCz5vwmjnqWqHEk3ZB1WOlwqBlRg83fqIWGmljZAzoZD"
$host = "https://graph.facebook.com/"

# TODO change to list of profiles from CSV
users = ["nicole.fox.71","me","rayhe"]
 
users.each do |u|
  frnds = getFriends(u)
  uid = getProfileInfo(u,"id")
  if(!frnds)
    puts "#{u} friends blocked"
  else
    persistFriends(uid,frnds)
  end
end

users.each do |u|
  uid = getProfileInfo(u,"id")
  if(!uid)
    puts "#{u} friends blocked"
  else
    checkRelationship(u,getProfileInfo(u,"id"))
  end
end
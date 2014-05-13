
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



#TODO move to ARGV
$accesstoken = "CAACEdEose0cBAPXOOyZAXuWdBuvroWCZC1WnU9rwWIHosKW0kDrbTzZBPZCqIIucrLV7uKlgAfqkHPR6pdYLAly9I3f30teZBGaM4NZBKbjEY1HCE5RGDPM1kkVKaMdSnRlBcGY91LZCSDD4wU7l4wlUlEud8Y9IBXuUZASOPp8ePZB8C1iz7PlgCyORLf4gHGEIZD"
$host = "https://graph.facebook.com/v1.0/"

# TODO change to list of profiles from CSV
users = []
CSV.foreach(ARGV[0], :headers => true) do |csv_obj|
   if(csv_obj["fb_id"].nil? == false)
      x = {"un" => csv_obj["fb_id"] , "id" => getProfileInfo(csv_obj["fb_id"],"id")}
      puts x
      users << x
   end
end

relations = []
users.peach(10) do |u|
    users.peach(10) do |t|
      if(getRelationship(u["id"],t["id"]))
        puts "Relationship found!"
        relations << { "targ" => u , "frnd" => t }
      end
    end
end

CSV.open("relationships.csv","w") do |csv|
  relations.each do |x|
    csv << [x["targ"]["un"],x["frnd"]["un"]]
  end
end
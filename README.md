FacebookFriendNetwork
=====================

Given a CSV list of Facebook profile usernames, will find all relationships between them.

Requirements
------------

- Rest Client ("gem install rest-client")
- Peach ("gem install peach)
- Facebook API Accesstoken (https://developers.facebook.com/tools/explorer/145634995501895/?method=GET&path=me%3Ffields%3Did%2Cname&version=v2.0)
- CSV List of Facebook Usernames in column title "fb_id"

Usage
-----

```
jruby createFriendNetwork.rb "<input csv file>" "<Facebook API Access token>"
```
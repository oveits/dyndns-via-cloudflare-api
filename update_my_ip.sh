
source $HOME/.cloudflare/credentials
# the content of the credentials file should look like follows:
# ZONE=your_zone
# EMAIL=your_email@example.com
# GLOBAL_API_KEY=your_global_api_key

[ "$NAME" == "" ] && NAME=ganesh.vocon-it.com
SLEEP=60

# output: e.g. 1.2.3.4

while (true); do
  IP=$(curl -4 -s ifconfig.co); 
  
  echo "My public IP is: $IP"
  
  ENTRY=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?type=A&name=$NAME&page=1&per_page=20&order=type&direction=desc&match=all" \
       -H "X-Auth-Email: $EMAIL" \
       -H "X-Auth-Key: $GLOBAL_API_KEY" \
       -H "Content-Type: application/json" )

  ID=$(echo "$ENTRY" | jq '.["result"][0]["id"]' | sed "s/\"//g")
  IP_ENTRY=$(echo "$ENTRY" | jq '.["result"][0]["content"]' | sed "s/\"//g")

  # echo ID=$ID
  #echo IP_ENTRY=$IP_ENTRY
  echo "The IP Address found on CloudFlare DNS is: $IP_ENTRY"

  #output: e.g. 828...588

  [ "$IP" != "" ] \
  && [ "$IP_ENTRY" != "" ] \
  && [ "$IP" != "$IP_ENTRY" ] \
  && curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records/$ID"  \
	  -H "X-Auth-Email: $EMAIL" \
	  -H "X-Auth-Key: $GLOBAL_API_KEY" \
	  -H "Content-Type: application/json" \
	  --data '{
          "type":"A",
          "name":"'$NAME'",
          "content":"'$IP'",
          "ttl":120,
          "priority":10,
          "proxied":false}' || echo "IP address has not changed; skipping. Checking again in $SLEEP seconds"

  # output: e.g.
  # {"result":{"id":"828...588","type"

  sleep $SLEEP

done

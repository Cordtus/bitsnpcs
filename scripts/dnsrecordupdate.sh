#!/bin/bash

# Fetch RECORD_ID for each domain
# DOMAIN=<URL>
# curl --request GET --url https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records -H "Content-Type: application/json" -H 'X-Auth-Email: $EMAIL' -H 'X-Auth-Key: $TOKEN' | json_pp

# Run the following script completed with DOMAINS + RECORD_IDS
# Create the LOG_FILE before running script
# chmod +x script to make executable

#################### CHANGE THE FOLLOWING VARIABLES ####################
RECORD_TYPE=""
EMAIL=""
API_KEY=""
DOMAINS=("" "" "")
RECORD_IDS=("" "" "")
ZONE_IDS=("" "" "")
LOG_FILE=""
########################################################################

CURRENT_IPV4="$(curl ifconfig.me)"
LAST_IPV4="$(tail -1 $LOG_FILE | awk -F, '{print $2}')"

if [ "$CURRENT_IPV4" = "$LAST_IPV4" ]; then
    echo "IP has not changed ($CURRENT_IPV4)"
else
    echo "IP has changed: $CURRENT_IPV4"
    echo "$(date),$CURRENT_IPV4" >> $LOG_FILE
    for I in ${!DOMAINS[@]}
    do
      DOMAIN=${DOMAINS[$I]}
      RECORD_ID=${RECORD_IDS[$I]}
          ZONE_ID=${ZONE_IDS[$I]}
      curl -X PUT --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID -H 'Content-Type: application/json' -H 'X-Auth-Email: '"$EMAIL"'' -H 'X-Auth-Key: '"$API_KEY"'' -d '{"content":"'"$CURRENT_IPV4"'", "name":"'"$DOMAIN"'", "type":"'"$RECORD_TYPE"'"}'
    done
fi

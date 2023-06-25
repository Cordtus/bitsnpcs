# keeps cloudflare dns records updated with dynamic IPv4 addr

## use the API to list 'ZONE_IDS' <br>
```$ curl --request GET --url https://api.cloudflare.com/client/v4/zones -H 'Content-Type: application/json' -H 'X-Auth-Email: $EMAIL' -H 'X-Auth-Key: $TOKEN' | json_pp```

<br>

## use 'ZONE_IDS' to find 'RECORD_IDS' for each domain, fill all variables in table below [maintain sequence as shown] <br>
```$ curl --request GET --url https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records -H "Content-Type: application/json" -H 'X-Auth-Email: $EMAIL' -H 'X-Auth-Key: $TOKEN' | json_pp```

<br>

## create LOG_FILE 
make sure user running script has write perms <br>

```$ touch /var/log/ip.log```

<br>

## create file wherever you keep scripts [optional]
```$ mkdir $HOME/scripts && touch $HOME/scripts/dnsautoupdate.sh```

<br>


## save completed script

```
$ cat <<'EOF' | sudo tee $HOME/scripts/dnsautoupdate.sh
#!/bin/bash

#################### FILL THESE VARIABLES ####################
NAME_TYPE="<name_type>"
EMAIL="<your@cloudflarelogin.address>"
TOKEN="<yourcloudflareapitoken>"
DOMAINS=("<domain1.com>" "<domain2.com>" "<domain3.com>")
RECORD_IDS=("<ID1>" "<ID2>" "<ID3>")
ZONE_IDS=("<ZONE1>" "<ZONE2>" "<ZONE3>")
LOG_FILE="/var/log/IP"
##############################################################

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
      curl -X PUT --url https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID -H 'Content-Type: application/json' -H 'X-Auth-Email: "'"$EMAIL"'"' -H 'X-Auth-Key: "'"$TOKEN"'"' -d '{"content":"'"$CURRENT_IPV4"'", "name":"'"$DOMAIN"'", "type":"'"$NAME_TYPE"'"}'
    done
fi
EOF
```
<br>

## make script executable
`chmod +x dnsautoupdate.sh`

<br>

## set a cron job to run script at chosen interval <br>

```$ crontab -e```

```
Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/vim.tiny
  4. /bin/ed
```

- add to end of cron file - this will run every 30 min <br>

`*/30 * * * * /path/to/dnsautoupdate.sh`

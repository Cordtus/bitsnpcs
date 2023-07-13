#!/bin/sh
#set $IBCD to ibc-port/ibc-channel/native-denom
#'transfer/channel-0/ujuno' 

echo -n $IBCD | openssl dgst -sha256 | tr '[:lower:]' '[:upper:]' | sed 's/^/ibc\//'

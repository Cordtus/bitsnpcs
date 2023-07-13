#!/bin/sh
#run with "ibc-port/ibc-channel/native-denom" as an arg

IBCD="$1"
echo -n $IBCD | openssl dgst -sha256 | awk '{print "ibc/" toupper($2)}'

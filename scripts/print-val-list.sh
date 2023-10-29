#!/bin/bash

DAEMOND="$1"
OUTPUT="$2"
TEMP=$(mktemp)
declare -a json_array

# Fetch validators and transform to JSON objects
$DAEMOND q staking validators -o json | jq '[.validators[] | {moniker: .description.moniker, pubkey: .consensus_pubkey.key}]' | jq -c '.[]' | while read -r line; do
moniker=$(echo "$line" | jq -r '.moniker')
pubkey=$(echo "$line" | jq -r '.pubkey')
pubkey_hex=$($DAEMOND debug pubkey-raw $pubkey -t ed25519 | grep "Address:" | sed 's/Address: //')
json_object=$(echo "$line" | jq --arg pubkey_hex $pubkey_hex '. + {address: $pubkey_hex}')
printf "%s,\n" "$json_object" >> $TEMP
done

# Remove last comma to make it a valid JSON array
sed '$ s/,$//' $TEMP > $OUTPUT

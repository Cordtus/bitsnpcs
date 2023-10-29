#!/bin/bash

daemond=$1
output_file=$2
temp_file="temp.json"

$daemond q staking validators -o json | jq '[.validators[] | {moniker: .description.moniker, pubkey: .consensus_pubkey.key}]' | \
jq -c '.[]' | while read -r line; do
moniker=$(echo "$line" | jq -r '.moniker')
pubkey=$(echo "$line" | jq -r '.pubkey')

pubkey_hex=$($daemond debug pubkey-raw "$pubkey" -t ed25519 | grep "Address:" | sed 's/Address: //')

echo "$line" | jq --arg pubkey_hex "$pubkey_hex" \
'. + {address: $pubkey_hex}' >> "$temp_file"
done

echo "[" > "$output_file"
cat "$temp_file" >> "$output_file"
echo "]" >> "$output_file"

rm "$temp_file"

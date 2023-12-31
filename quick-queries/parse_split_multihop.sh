#!/bin/bash

# Check if a transaction hash argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <tx_hash>"
    exit 1
fi

# Assign the argument to a variable
HASH=$1

# Use curl to fetch transaction data and process it with jq
curl -s "https://lcd.osmosis.zone/cosmos/tx/v1beta1/txs/$HASH" | jq '[.tx_response.logs[] | .events[] | select(.type == "token_swapped") | {pool_id: (.attributes[] | select(.key == "pool_id").value), tokens_in: (.attributes[] | select(.key == "tokens_in").value), tokens_out: (.attributes[] | select(.key == "tokens_out").value)}]'

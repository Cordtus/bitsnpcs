#!/bin/bash
RPCADDR=$1
# Fetch the values using curl and jq
max_peer_block_height=$(curl -s $RPCADDR/status | jq -r '.result.sync_info.max_peer_block_height')
latest_block_height=$(curl -s $RPCADDR/status | jq -r '.result.sync_info.latest_block_height')

# Calculate the difference
difference=$((max_peer_block_height - latest_block_height))

# Print the difference
echo "Difference: $difference"

#!/bin/bash

# Usage:
# To check the last BLOCKS_TO_CHECK blocks:
# ./blockcheck.sh <RPC_ADDRESS> <BLOCKS_TO_CHECK>
# Example: ./blockcheck.sh http://localhost:26657 100

# To check blocks from a specific start height to an end height:
# ./blockcheck.sh <RPC_ADDRESS> <BLOCKS_TO_CHECK> <START_HEIGHT> <END_HEIGHT>
# Example: ./blockcheck.sh http://localhost:26657 100 18456000 18456100

RPCADDR=$1
BLOCKS_TO_CHECK=$2
START_HEIGHT=$3
END_HEIGHT=$4

# Determine the start and end block heights based on the provided arguments
if [[ -z "$START_HEIGHT" || -z "$END_HEIGHT" ]]; then
  VALIDATOR_ADDR=$(curl -s $RPCADDR/status | jq -r .result.validator_info.address)
  LAST_BLOCK=$(curl -s $RPCADDR/block | jq -r .result.block.header.height)
  START_BLOCK=$(expr $LAST_BLOCK - $BLOCKS_TO_CHECK)
  END_BLOCK=$LAST_BLOCK
else
  START_BLOCK=$START_HEIGHT
  END_BLOCK=$END_HEIGHT
fi

# Initialize tally for block statuses
declare -A tally
tally[signed]=0
tally[not_signed]=0
tally[no_signature_info]=0
tally[unknown_signature_flag]=0

# Function to fetch block data
fetch_block() {
    local block=$1
    curl -s $RPCADDR/block?height=$block | jq -c ". | {height: .result.block.header.height, signatures: .result.block.last_commit.signatures}"
}

# Function to process block data and update tally
process_block() {
    local block_data=$1
    local validator=$2

    height=$(echo $block_data | jq -r '.height')
    result=$(echo $block_data | jq -r --arg validator "$validator" '.signatures[] | select(.validator_address==$validator).block_id_flag')

    if [ -z "$result" ]; then
        echo "Block $height: no signature info"
        ((tally[no_signature_info]++))
    elif [ "$result" == "2" ]; then
        echo "Block $height: signed"
        ((tally[signed]++))
    elif [ "$result" == "1" ]; then
        echo "Block $height: not signed"
        ((tally[not_signed]++))
    else
        echo "Block $height: unknown signature flag: $result"
        ((tally[unknown_signature_flag]++))
    fi
}

export -f fetch_block
export -f process_block
export RPCADDR
export VALIDATOR_ADDR

# Fetch and process blocks in parallel
seq $START_BLOCK $END_BLOCK | xargs -n 1 -P 10 -I {} bash -c 'process_block "$(fetch_block {})" "$VALIDATOR_ADDR"'

# Print summary of block statuses
echo "Summary:"
echo "Signed blocks: ${tally[signed]}"
echo "Not signed blocks: ${tally[not_signed]}"
echo "No signature info: ${tally[no_signature_info]}"
echo "Unknown signature flag: ${tally[unknown_signature_flag]}"

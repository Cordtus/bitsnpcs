#!/bin/bash

# Function to check if a command exists, and install it if it doesn't
ensure_command() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 could not be found. Installing..."
        sudo apt-get update
        sudo apt-get install -y $1
    else
        echo "$1 is already installed."
    fi
}

# Ensure required commands are installed
ensure_command curl
ensure_command jq
ensure_command parallel

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

# Function to fetch and process block data
fetch_and_process_block() {
    local block=$1
    local validator=$2

    block_data=$(curl -s $RPCADDR/block?height=$block | jq -c ". | {height: .result.block.header.height, signatures: .result.block.last_commit.signatures}")

    height=$(echo $block_data | jq -r '.height')
    result=$(echo $block_data | jq -r --arg validator "$validator" '.signatures[] | select(.validator_address==$validator).block_id_flag')

    if [ -z "$result" ]; then
        echo "Block $height: no signature info"
        echo "no_signature_info"
    elif [ "$result" == "2" ]; then
        echo "Block $height: signed"
        echo "signed"
    elif [ "$result" == "1" ]; then
        echo "Block $height: not signed"
        echo "not_signed"
    else
        echo "Block $height: unknown signature flag: $result"
        echo "unknown_signature_flag"
    fi
}

export -f fetch_and_process_block
export RPCADDR
export VALIDATOR_ADDR

# Fetch and process blocks in parallel, aggregating results
seq $START_BLOCK $END_BLOCK | parallel -j 10 fetch_and_process_block {} $VALIDATOR_ADDR | tee results.txt

# Process the results
while IFS= read -r line; do
    case $line in
        signed) ((tally[signed]++)) ;;
        not_signed) ((tally[not_signed]++)) ;;
        no_signature_info) ((tally[no_signature_info]++)) ;;
        unknown_signature_flag) ((tally[unknown_signature_flag]++)) ;;
    esac
done < results.txt

# Print summary of block statuses
echo "Summary:"
echo "Signed blocks: ${tally[signed]}"
echo "Not signed blocks: ${tally[not_signed]}"
echo "No signature info: ${tally[no_signature_info]}"
echo "Unknown signature flag: ${tally[unknown_signature_flag]}"

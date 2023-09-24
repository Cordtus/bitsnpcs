#!/bin/bash

#show average block size for tendermint chain [250 most blocks default]
#specify range of blocks by flags '-s', '-e' [potentially extreme hurt to node]
#getblksize.sh http://rpc.node:26657 -s 128900 -e 133900

# Initialize variables to keep track of the sum and count
total_size=0
count=0

# Initialize start_height and end_height to empty
start_height=""
end_height=""

# Parse command-line flags for start_height and end_height
while getopts ":s:e:" opt; do
  case $opt in
    s) start_height="$OPTARG"
    ;;
    e) end_height="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Remove the flags that were parsed by getopts
shift $((OPTIND-1))

# RPC endpoint
rpc=$1

# Check if RPC endpoint is specified
if [[ -z "$rpc" ]]; then
  echo "Usage: $0 [-s start_height] [-e end_height] <rpc_endpoint>"
  exit 1
fi

# Fetch the current block height if end_height is not specified
if [[ -z "$end_height" ]]; then
  end_height=$(curl -s "$rpc/block" | jq -r '.result.block.header.height')
fi

# Calculate the start_height if not specified
if [[ -z "$start_height" ]]; then
  start_height=$((end_height - 250))
fi

# Check if current_height and start_height were successfully set
if [[ -z "$end_height" || -z "$start_height" ]]; then
  echo "Could not determine block heights."
  exit 1
fi

echo "Fetching blocks from height $start_height to $end_height."

# Iterate over the determined range of block heights
for height in $(seq "$start_height" "$end_height"); do
  # Use curl to fetch the block data and get the size of downloaded data
  size=$(curl -s "$rpc/block?height=$height" -o /dev/null -s -S -w "%{size_download}")

  # Accumulate the size and increment the count
  total_size=$((total_size + size))
  count=$((count + 1))
done

# Calculate the average size
if [ "$count" -gt 0 ]; then
  average_size=$(echo "scale=2; $total_size / $count" | bc)
  echo "Average Size: $average_size bytes"
else
  echo "No blocks were fetched. Average size cannot be calculated."
fi

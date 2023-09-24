#!/bin/bash

# Show average block size for a Tendermint chain (250 most recent blocks by default).
# Specify the range of blocks by flags '-s', '-e' (potential extreme load on the node).
# Excludes invalid or rate-limited calls from the final result.

# Temporary file to hold individual downloaded sizes
temp_file=$(mktemp)

fetch_block() {
    local rpc=$1
    local height=$2
    local response=$(curl -s "$rpc/block?height=$height")
    local size=$(echo -n "$response" | wc -c)

    local has_block_id=$(echo "$response" | jq -e '.result.block_id' > /dev/null 2>&1; echo $?)
    local has_header=$(echo "$response" | jq -e '.result.block.header' > /dev/null 2>&1; echo $?)

    if [[ $has_block_id -eq 0 && $has_header -eq 0 ]]; then
        echo $size >> $temp_file
    else
        echo "Skipped block $height due to non-standard format or fetch failure."
    fi
}

export -f fetch_block
export temp_file

# Check if the first argument (RPC endpoint) is present
if [[ -z "$1" ]]; then
    echo "Usage: $0 <rpc_endpoint> [-s start_height] [-e end_height]"
    exit 1
fi

# Assign the first argument to the rpc variable and shift arguments
rpc=$1
shift

# Process flags
start_height=""
end_height=""

while getopts ":s:e:" opt; do
    case $opt in
        s) start_height="$OPTARG";;
        e) end_height="$OPTARG";;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
    esac
done

# Set default heights if not specified
if [[ -z "$end_height" ]]; then
    end_height=$(curl -s "$rpc/block" | jq -r '.result.block.header.height')
fi

if [[ -z "$start_height" ]]; then
    start_height=$((end_height - 250))
fi

# Concurrently fetch block sizes
for height in $(seq "$start_height" "$end_height"); do
    fetch_block "$rpc" "$height" &
    if (( $(jobs -p | wc -l) >= 10 )); then
        wait -n
    fi
done

# Wait for all jobs to complete
wait

# Calculate total_size and count
total_size=$(awk '{s+=$1} END {print s}' $temp_file)
count=$(wc -l < $temp_file)

# Remove temporary file
rm -f $temp_file

# Calculate and display average size
if [ "$count" -gt 0 ]; then
    average_size=$(echo "scale=2; $total_size / $count" | bc)
    echo "Average Size: $average_size bytes"
else
    echo "No blocks were fetched. Average size cannot be calculated."
fi

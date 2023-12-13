#!/bin/bash

NODE_ADDRESS=$1
KNOWN_GOOD_NODE_ADDRESS=$2

# Check if two arguments were provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 NodeIP:Port KnownGoodNodeIP:Port"
    exit 1
fi

query_known_good_node() {
    # Execute the query and extract the latest block height
    KNOWN_GOOD_HEIGHT=$(curl -s $KNOWN_GOOD_NODE_ADDRESS/status | jq -r .result.sync_info.latest_block_height)

    # Check if jq extracted a valid number
    if ! [[ "$KNOWN_GOOD_HEIGHT" =~ ^[0-9]+$ ]]; then
        echo "Error: Failed to extract block height from known-good node"
        return
    fi

    # Check if COUNT is greater than 0 and AVERAGE_RATE is greater than 0 using bc
    if [ $COUNT -gt 0 ] && [ $(echo "$AVERAGE_RATE > 0" | bc) -eq 1 ]; then
        HEIGHT_DIFF=$((KNOWN_GOOD_HEIGHT - CURRENT_HEIGHT))
        CATCH_UP_TIME=$(echo "scale=2; $HEIGHT_DIFF / $AVERAGE_RATE" | bc)
        echo "Known-good node height: $KNOWN_GOOD_HEIGHT, Estimated catch-up time (seconds): $CATCH_UP_TIME"
    fi
}

INTERVAL=10  # Interval for querying the first node
KNOWN_GOOD_INTERVAL=60 # Interval for querying the known-good node
COUNT=0
SUM=0
PREV_HEIGHT=0
AVERAGE_RATE=0

while true; do
    # Query the first node
    CURRENT_HEIGHT=$(curl -s $NODE_ADDRESS/status | jq -r .result.sync_info.latest_block_height)

    # Check if jq extracted a valid number
    if ! [[ "$CURRENT_HEIGHT" =~ ^[0-9]+$ ]]; then
        echo "Error: Failed to extract block height"
        exit 2
    fi

    # Calculate the average rate
    if [ $COUNT -gt 0 ]; then
        DIFF=$((CURRENT_HEIGHT - PREV_HEIGHT))
        SUM=$((SUM + DIFF))
        AVERAGE_RATE=$(echo "scale=2; ($SUM / $COUNT) / $INTERVAL" | bc)
        echo "Node height: $CURRENT_HEIGHT, Average blocks synced per second: $AVERAGE_RATE"
    fi

    PREV_HEIGHT=$CURRENT_HEIGHT
    COUNT=$((COUNT + 1))

    # Query the known-good node every minute
    if [ $((COUNT % (KNOWN_GOOD_INTERVAL / INTERVAL))) -eq 0 ]; then
        query_known_good_node
    fi

    sleep $INTERVAL
done

#~/bin/bash
#query validator rpc for recent signed blocks
#usage - script.sh <validator_address:rpc_port> <#_blocks_to_check>
RPCADDR=$1
BLOCKS_TO_CHECK=$2
VALIDATOR_ADDR=$(curl -s $RPCADDR/status | jq -r .result.validator_info.address)

LAST_BLOCK=$(curl -s $RPCADDR/block | jq -r .result.block.header.height)
START_BLOCK=$(expr $LAST_BLOCK - $BLOCKS_TO_CHECK)

for BLOCK in $(seq $START_BLOCK $LAST_BLOCK); do
    RESULT=$(curl -s $RPCADDR/block?height=$BLOCK | jq ".result.block.last_commit.signatures[] | select(.validator_address==\"$VALIDATOR_ADDR\").block_id_flag")

    if [ -z "$RESULT" ]; then
        echo "Block $BLOCK: no signature info"
    elif [ "$RESULT" == "2" ]; then
        echo "Block $BLOCK: signed"
    elif [ "$RESULT" == "1" ]; then
        echo "Block $BLOCK: not signed"
    else
        echo "Block $BLOCK: unknown signature flag: $RESULT"
    fi
done

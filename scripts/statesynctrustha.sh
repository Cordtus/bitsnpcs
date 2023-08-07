#!/bin/bash
#run this script with rpc URL or ip:port as an arg
#./statesynctrustha.sh https://rpc.nomic-testnet.basementnodes.ca
RPCADDR=$1
curl -s $RPCADDR/block | jq -r '.result.block.header.height + "\n" + .result.block_id.hash'

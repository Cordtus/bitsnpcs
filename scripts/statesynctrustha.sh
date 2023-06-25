#!/bin/bash
#replace localhost with the RPC node you are using for state sync
curl -s localhost:26650/block | \
jq -r '.result.block.header.height + "\n" + .result.block_id.hash'

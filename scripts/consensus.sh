#!/bin/sh

RPC=$1

curl -s $RPC/consensus_state | jq -r '.result.round_state.height_vote_set[].prevotes_bit_array'
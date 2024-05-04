#!/bin/bash

# ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# remove trailing slashes from URL
sanitize_url() {
  echo "$1" | sed 's:/*$::'
}

# make API request
fetch_data() {
  local url=$1
  local data=$(curl -s --fail "$url")
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error fetching data from $url${NC}"
    exit 1
  fi
  echo "$data"
}

# validate inputs (channel ID, port ID)
validate_id() {
  if ! [[ $1 =~ ^[a-zA-Z]+-[0-9]{1,5}$ ]]; then
    echo -e "${RED}Invalid format for $2. Expecting format like 'xxx-0' where 'xxx' can be 'channel', 'connection', or 'client' followed by up to 5 digits.${NC}"
    exit 1
  fi
}

# prompt for REST address
echo -e "${YELLOW}Enter REST API address (without trailing slash): ${NC}"
read -r restAddress
restAddress=$(sanitize_url "$restAddress")

# prompt for channel ID
echo -e "${YELLOW}Enter channel ID: ${NC}"
read -r channelId
validate_id "$channelId" "channel ID"

# prompt for port ID - default 'transfer'
echo -e "${YELLOW}Enter port ID (default: 'transfer'): ${NC}"
read -r portId
if [[ -z "$portId" ]]; then
    portId="transfer"
fi

# fetch channel
channelData=$(fetch_data "${restAddress}/ibc/core/channel/v1/channels/${channelId}/ports/${portId}")
counterpartyChannelId=$(echo "$channelData" | jq -r '.channel.counterparty.channel_id')
connectionId=$(echo "$channelData" | jq -r '.channel.connection_hops[0]')

# fetch connection
connectionData=$(fetch_data "${restAddress}/ibc/core/connection/v1/connections/${connectionId}")
clientId=$(echo "$connectionData" | jq -r '.connection.client_id')
counterpartyClientId=$(echo "$connectionData" | jq -r '.connection.counterparty.client_id')
counterpartyConnectionId=$(echo "$connectionData" | jq -r '.connection.counterparty.connection_id')

# check for errors in outputs
if ! [[ $clientId =~ ^[0-9]+-tendermint-[0-9]{1,5}$ ]]; then
  echo -e "${RED}Unexpected format in fetched client ID. Received: $clientId${NC}"
fi

# prepare JSON output
json_output=$(jq -n --arg channelId "$channelId" \
                      --arg clientId "$clientId" \
                      --arg connectionId "$connectionId" \
                      --arg counterpartyChannelId "$counterpartyChannelId" \
                      --arg counterpartyClientId "$counterpartyClientId" \
                      --arg counterpartyConnectionId "$counterpartyConnectionId" \
  '{
    channelId: $channelId,
    clientId: $clientId,
    connectionId: $connectionId,
    counterparty_channelId: $counterpartyChannelId,
    counterparty_clientId: $counterpartyClientId,
    counterparty_connectionId: $counterpartyConnectionId
  }')

# print pretty
echo -e "${GREEN}${json_output}${NC}"

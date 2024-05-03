#!/bin/bash

# ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# array to hold the values
declare -A ibc_values

# rompt for REST address and channel ID
echo -e "${YELLOW}Enter REST API address: ${NC}"
read -p "" restAddress
echo -e "${YELLOW}Enter channel ID: ${NC}"
read -p "" channelId

# store initial channelId
ibc_values["channelId"]=$channelId

# fetch client ID
clientId=$(curl -s "${restAddress}/ibc/core/channel/v1/channels/${channelId}/ports/transfer/client_state" | jq -r '.identified_client_state.client_id')
ibc_values["clientId"]=$clientId

# fetch connection ID
connectionId=$(curl -s "${restAddress}/ibc/core/connection/v1/client_connections/${clientId}" | jq -r '.connection_paths[0]')
ibc_values["connectionId"]=$connectionId

# fetch counterparty client and connection IDs
counterpartyInfo=$(curl -s "${restAddress}/ibc/core/connection/v1/connections/${connectionId}" | jq)
counterpartyClientId=$(echo $counterpartyInfo | jq -r '.connection.counterparty.client_id')
counterpartyConnectionId=$(echo $counterpartyInfo | jq -r '.connection.counterparty.connection_id')

# confirm fetched client_id matches the stored clientId
fetchedClientId=$(echo $counterpartyInfo | jq -r '.connection.client_id')
if [[ "$fetchedClientId" != "${ibc_values["clientId"]}" ]]; then
  echo -e "${RED}Warning: Mismatch in client IDs fetched.${NC}"
fi

# fetch counterparty details
ibc_values["counterparty_clientId"]=$counterpartyClientId
ibc_values["counterparty_connectionId"]=$counterpartyConnectionId

# fetch the counterparty channel ID using the stored connectionId
counterpartyChannelInfo=$(curl -s "${restAddress}/ibc/core/channel/v1/connections/${connectionId}/channels" | jq)
counterpartyChannelId=$(echo $counterpartyChannelInfo | jq -r '.channels[0].counterparty.channel_id')

# fetch counterparty channel ID
ibc_values["counterparty_channelId"]=$counterpartyChannelId

# prepare and order JSON output
json_output="{"
json_output+="\"clientId\":\"${ibc_values["clientId"]}\","
json_output+="\"channelId\":\"${ibc_values["channelId"]}\","
json_output+="\"connectionId\":\"${ibc_values["connectionId"]}\","
json_output+="\"counterparty_clientId\":\"${ibc_values["counterparty_clientId"]}\","
json_output+="\"counterparty_channelId\":\"${ibc_values["counterparty_channelId"]}\","
json_output+="\"counterparty_connectionId\":\"${ibc_values["counterparty_connectionId"]}\""
json_output+="}"

# prettify JSON output
pretty_json=$(echo $json_output | jq .)

# print pretty JSON
echo -e "${GREEN}$pretty_json${NC}"

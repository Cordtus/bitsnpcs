#!/bin/bash

# accepts 3 args: REST URL, contract address, payload [json string]
# remembers last-entered values for first 2 args
# payload "test" set as alias for '{"a":"b"}' to return valid query methods

# File to store the last used values
config_file="last_run.conf"

# Load previous values if the file exists
if [ -f "$config_file" ]; then
    source $config_file
fi

# Function to get user input with default
function get_input() {
    local input
    local default_value=$2
    read -p "$1 [$default_value]: " input
    echo "${input:-$default_value}"
}

# Prompt for restAddress
restAddress=$(get_input "Enter the REST API address" "$restAddress")

# Prompt for contractAddress
contractAddress=$(get_input "Enter the contract address" "$contractAddress")

# Prompt for payload and check if input is 'test'
payLoad=$(get_input "Enter the payload (or 'test' for default)" "$payLoad")
if [ "$payLoad" == "test" ]; then
    payLoad='{"a":"b"}'
fi

# Encode payload to base64
payLoad_base64=$(echo "$payLoad" | base64 -w 0) # -w 0 to disable line wrapping

# Save the latest inputs
echo "restAddress='$restAddress'" > $config_file
echo "contractAddress='$contractAddress'" >> $config_file
echo "payLoad='$payLoad'" >> $config_file

# Build the URL and make the HTTP GET request
url="${restAddress}/cosmwasm/wasm/v1/contract/${contractAddress}/smart/${payLoad_base64}"
response=$(curl -s --write-out "\n%{http_code}" --url "$url")

# Separate the status code from the response body
http_code=$(echo "$response" | tail -n1)  # Last line of output is the HTTP status code
response_body=$(echo "$response" | head -n -1)  # Remove the last line (status code)

# Check if the response is successful
if [ "$http_code" -eq 200 ]; then
    # Print pretty JSON
    echo "$response_body" | jq .
else
    echo "Error: HTTP status $http_code"
    echo "$response_body"
fi

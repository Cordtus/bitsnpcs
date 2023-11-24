import requests
import json
import argparse
import base64

# Example
# python3 ./scripts/btcqtx.py 014050d595958dd3f6874478a728e5e6eb4c8b5f8572cb1e5332ffb3136b21ea --mempool


# Replace with your Bitcoin Core RPC credentials and node details
rpc_user = "nomic"
rpc_password = "soon"
rpc_url = "http://localhost:18332"

# Create an argument parser to accept the TxID as an argument
parser = argparse.ArgumentParser(description="Query Bitcoin Transaction Information by TxID")
parser.add_argument("txid", help="Transaction ID (TxID) to query")

# Add an optional argument to specify mempool transactions
parser.add_argument("--mempool", action="store_true", help="Search in mempool")

# Parse the command-line arguments
args = parser.parse_args()

# Extract the transaction hash (TxID) from the command-line arguments
txid = args.txid

# Create a JSON-RPC request payload for getrawtransaction method
payload = {
"method": "getrawtransaction",
"params": [txid, args.mempool],
"jsonrpc": "2.0",
"id": 1
}

# Create the HTTP Basic Auth header
headers = {
"Authorization": f"Basic {base64.b64encode(f'{rpc_user}:{rpc_password}'.encode()).decode()}"
}

# Send the POST request to the Bitcoin Core node
response = requests.post(rpc_url, json=payload, headers=headers)

# Send the POST request to the Bitcoin Core node
response = requests.post(rpc_url, json=payload, headers=headers)

# Check the response
if response.status_code == 200:
result = response.json()
print("Transaction Information:")
print(json.dumps(result["result"], indent=4))
else:
print("Error:", response.status_code, response.text)

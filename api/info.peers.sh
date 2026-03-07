#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Snow (Numbers Testnet) subnet ID
SNOW_SUBNET_ID="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"
# Jade (Numbers Mainnet) subnet ID
JADE_SUBNET_ID="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"

TESTNET_URL="https://api.avax-test.network"
MAINNET_URL="https://api.avax.network"

# Fetch current validator node IDs for a subnet and return as a JSON array
get_node_ids_json() {
    local url="$1"
    local subnet_id="$2"
    curl -s -X POST --data "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"platform.getCurrentValidators\",
        \"params\": {\"subnetID\": \"${subnet_id}\"},
        \"id\": 1
    }" -H 'content-type:application/json;' "${url}/ext/bc/P" \
        | jq '[.result.validators[].nodeID]'
}

# Snow
echo "========== Snow nodes information =========="
SNOW_NODE_IDS=$(get_node_ids_json "${TESTNET_URL}" "${SNOW_SUBNET_ID}")
curl -X POST --data "{
    \"jsonrpc\":\"2.0\",
    \"id\"     :1,
    \"method\" :\"info.peers\",
    \"params\": {\"nodeIDs\": ${SNOW_NODE_IDS}}
}" -H 'content-type:application/json;' "${TESTNET_URL}/ext/info" | jq .

# Jade
echo "========== Jade nodes information =========="
JADE_NODE_IDS=$(get_node_ids_json "${MAINNET_URL}" "${JADE_SUBNET_ID}")
curl -X POST --data "{
    \"jsonrpc\":\"2.0\",
    \"id\"     :1,
    \"method\" :\"info.peers\",
    \"params\": {\"nodeIDs\": ${JADE_NODE_IDS}}
}" -H 'content-type:application/json;' "${MAINNET_URL}/ext/info" | jq .


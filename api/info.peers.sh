#!/bin/bash

# shellcheck source=peers.conf
source peers.conf

# Snow
echo "========== Snow nodes information =========="
curl -X POST --data "{
    \"jsonrpc\":\"2.0\",
    \"id\":1,
    \"method\":\"info.peers\",
    \"params\": {
        \"nodeIDs\": ${SNOW_NODE_IDS}
    }
}" -H 'content-type:application/json;' https://api.avax-test.network/ext/info | jq .

# Jade
echo "========== Jade nodes information =========="
curl -X POST --data "{
    \"jsonrpc\":\"2.0\",
    \"id\":1,
    \"method\":\"info.peers\",
    \"params\": {
        \"nodeIDs\": ${JADE_NODE_IDS}
    }
}" -H 'content-type:application/json;' https://api.avax.network/ext/info | jq .


#!/bin/bash

source env.sh

NODE_IDS="${1:-}"
ENDPOINT="${2:-${URL}}"

curl -X POST --data "{
    \"jsonrpc\":\"2.0\",
    \"id\"     :1,
    \"method\" :\"info.peers\",
    \"params\": {
        \"nodeIDs\": [${NODE_IDS}]
    }
}" -H 'content-type:application/json;' ${ENDPOINT}/ext/info | jq .


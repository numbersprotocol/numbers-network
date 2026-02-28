#!/bin/bash

BLOCKCHAIN_ID="$1"

curl -X POST --data "$(jq -n --arg id "${BLOCKCHAIN_ID}" \
    '{"jsonrpc":"2.0","method":"platform.validatedBy","params":{"blockchainID":$id},"id":1}')" \
    -H 'content-type:application/json;' 127.0.0.1:9650/ext/bc/P

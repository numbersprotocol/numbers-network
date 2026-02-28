#!/bin/bash
#
# Note: The bootstrapping process takes approximately 50–100 hours and requires 100 GB of space.
# https://chainstack.com/avalanche-subnet-tutorial-series-running-a-local-avalanche-node-on-fuji-testnet/

URL="127.0.0.1:9650"
SUBNET_ID="$1"
curl -X POST --data "$(jq -n --arg id "${SUBNET_ID}" \
    '{"jsonrpc":"2.0","method":"platform.getCurrentValidators","params":{"subnetID":$id},"id":1}')" \
    -H 'content-type:application/json;' "${URL}/ext/bc/P"

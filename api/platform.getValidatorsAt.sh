#!/bin/bash

source env.sh

SUBNET_ID="$1"
HEIGHT="${2:-1}"

curl -X POST --data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"platform.getValidatorsAt\",
    \"params\": {
        \"height\":${HEIGHT},
	\"subnetID\": \"${SUBNET_ID}\"
    },
    \"id\": 1
}" -H 'content-type:application/json;' ${URL}/ext/bc/P

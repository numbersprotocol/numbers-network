#!/bin/bash

SUBNET_ID="$1"

curl -X POST --data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"platform.validates\",
    \"params\": {
        \"subnetID\":\"${SUBNET_ID}\"
    },
    \"id\": 1
}" -H 'content-type:application/json;' 127.0.0.1:9650/ext/bc/P


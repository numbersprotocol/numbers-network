#!/bin/bash

# shellcheck source=env.sh
source env.sh
SUBNET_ID="$1"

curl -X POST --data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"platform.validates\",
    \"params\": {
        \"subnetID\":\"${SUBNET_ID}\"
    },
    \"id\": 1
}" -H 'content-type:application/json;' "${URL}/ext/bc/P"


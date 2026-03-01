#!/bin/bash
#
# Note: The bootstrapping process takes approximately 50–100 hours and requires 100 GB of space.
# https://chainstack.com/avalanche-subnet-tutorial-series-running-a-local-avalanche-node-on-fuji-testnet/

# shellcheck source=env.sh
source env.sh

echo "URL: ${URL}"

curl -X POST --data '{
    "jsonrpc": "2.0",
        "method": "platform.getSubnets",
	    "params": {},
	        "id": 1
	}' -H 'content-type:application/json;' "${URL}/ext/bc/P"

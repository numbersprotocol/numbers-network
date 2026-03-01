#!/bin/bash

# shellcheck source=env.sh
source env.sh

curl -X POST --data '{
    "jsonrpc":"2.0",
        "id"     :1,
	    "method" :"health.health"
    }' -H 'content-type:application/json;' "${URL}/ext/health"

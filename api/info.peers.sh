#!/bin/bash

# Snow
echo "========== Snow nodes information =========="
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.peers",
    "params": {
        "nodeIDs": [
            "NodeID-7TwAjiRpTbNcqUx6F9EoyXRBLAfeoQXRq",
            "NodeID-JbeonHKqomERomXgCiXr9oC9vfynkBupj",
            "NodeID-BffXkmzM8EwrBZgpqFp9pwgE9DbDgYKG2",
            "NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW",
            "NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p"
        ]
    }
}' -H 'content-type:application/json;' https://api.avax-test.network/ext/info | jq .

# Jade
echo "========== Jade nodes information =========="
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.peers",
    "params": {
        "nodeIDs": [
            "NodeID-BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx"
        ]
    }
}' -H 'content-type:application/json;' https://api.avax.network/ext/info | jq .


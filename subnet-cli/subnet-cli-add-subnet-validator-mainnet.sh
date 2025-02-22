#!/bin/bash
# Validator ID source: https://app.asana.com/0/1202305127727547/1202919355642524/f

NODE_ID="NodeID-BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx"
SUBNET_ID="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"

subnet-cli add subnet-validator \
    --node-ids="${NODE_ID}" \
    --subnet-id="${SUBNET_ID}" \
    --public-uri "https://api.avax.network"

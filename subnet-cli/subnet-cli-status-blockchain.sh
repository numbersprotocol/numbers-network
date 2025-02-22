#!/bin/bash

# Numbers devnet
BLOCKCHAIN_ID="$1"

subnet-cli status blockchain \
    --private-uri="http://127.0.0.1:9650" \
    --blockchain-id=${BLOCKCHAIN_ID} \
    --check-bootstrapped

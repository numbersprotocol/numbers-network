#!/bin/bash

# Numbers devnet
BLOCKCHAIN_ID="$1"

if [[ ! "${BLOCKCHAIN_ID}" =~ ^[a-km-zA-HJ-NP-Z1-9]+$ ]]; then
    echo "Error: invalid blockchain ID. Only base58 characters are allowed." >&2
    exit 1
fi

subnet-cli status blockchain \
    --private-uri="http://127.0.0.1:9650" \
    --blockchain-id="${BLOCKCHAIN_ID}" \
    --check-bootstrapped

#!/bin/bash
#
# https://docs.avax.network/subnets/create-a-fuji-subnet-subnet-cli#build-binary

# Example: numbersevm
SUBNET_EVM_NAME="$1"

if [[ ! "${SUBNET_EVM_NAME}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: invalid VM name. Only alphanumeric characters, hyphens, and underscores are allowed." >&2
    exit 1
fi

subnet-cli create VMID "${SUBNET_EVM_NAME}"


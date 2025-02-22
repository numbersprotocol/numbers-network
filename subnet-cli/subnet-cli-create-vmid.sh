#!/bin/bash
#
# https://docs.avax.network/subnets/create-a-fuji-subnet-subnet-cli#build-binary

# Example: numbersevm
SUBNET_EVM_NAME="$1"

subnet-cli create VMID $SUBNET_EVM_NAME


#!/bin/bash
# Validator ID source: https://app.asana.com/0/1202305127727547/1202919355642524/f

NODE_ID="NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p"
SUBNET_ID="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"

subnet-cli add subnet-validator \
    --node-ids="${NODE_ID}" \
    --subnet-id="${SUBNET_ID}"

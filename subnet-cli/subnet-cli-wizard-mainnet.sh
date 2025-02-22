#!/bin/bash
#
# --node-ids: If you have multiple nodes, use comma to separate them.
#             Ex: NodeID-8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF,NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW
#
# subnet-cli for mainnet: https://docs.avax.network/subnets/subnet-cli#network-selection

subnet-cli wizard \
    --node-ids NodeID-BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx \
    --vm-genesis-path ./genesis.json \
    --vm-id qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx \
    --chain-name numbersevm \
    --public-uri https://api.avax.network


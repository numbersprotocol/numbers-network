#!/bin/bash
#
# --node-ids: If you have multiple nodes, use comma to separate them.
#             Ex: NodeID-8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF,NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW

subnet-cli wizard \
    --node-ids NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW,NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p \
    --vm-genesis-path ../genesis/genesis-nativecoin-feemgr-feerecv.json \
    --vm-id kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT \
    --chain-name captevm


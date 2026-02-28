#!/bin/bash
#
# {
#   "id": "fdesjrz477ot2iuUKdrGUephzHEfMN6AayMaWGXxhnZfkGRYr",
#   "name": "captevm",
#   "subnetID": "GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL",
#   "vmID": "kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT"
# }

source env.sh

BLOCKCHAIN_ID="$1"

curl -X POST --data "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"platform.getBlockchainStatus\",
    \"params\":{
        \"blockchainID\":\"${BLOCKCHAIN_ID}\"
    },
    \"id\": 1
}" -H 'content-type:application/json;' ${URL}/ext/bc/P

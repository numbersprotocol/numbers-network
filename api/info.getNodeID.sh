#!/bin/bash
#
# Pre-running a node on Chainstake
#
# Expected Output
# {"jsonrpc":"2.0","result":{"nodeID":"NodeID-JRhJd4Qn4WTjP28RUFDQa2NC59deo7tT6"},"id":1}

URL="127.0.0.1:9650"

curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.getNodeID"
}' -H 'content-type:application/json;' ${URL}/ext/info

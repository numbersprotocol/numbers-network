#!/bin/bash

source env.sh

curl -X POST --data '{
    "jsonrpc":"2.0",
    "id" :1,
    "method" :"platform.getBlockchains",
    "params" :{}
}' -H 'content-type:application/json;' ${URL}/ext/P

#!/bin/bash

# shellcheck source=env.sh
source env.sh

curl -X POST "${URL}/ext/metrics"

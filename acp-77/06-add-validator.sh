#!/bin/bash
#
# ACP-77: Add an L1 validator (post-conversion)
#
# Adds a new validator to the L1 via the ValidatorManager contract.
# The node must be running and synced before adding it as a validator.
#
# Prerequisites:
#   - Subnet converted to L1 and ValidatorManager initialized
#   - Target node is running and fully bootstrapped
#
# Usage:
#   ./06-add-validator.sh <node-id> <bls-public-key> <bls-pop> [weight]
#   ./06-add-validator.sh <node-id>   # Prompts for BLS keys
#
# Examples:
#   # Testnet - add validator-a1
#   ./06-add-validator.sh \
#       NodeID-EBraJb3KNnEia5UNa4DrsEXx86GL6mxyx \
#       0x86b95562bdb3605d3a91bfe400e621c8b27135310d167e2108b92893b21068cf821eff6021f37710ce8efa63baa32ad5 \
#       0xa2718e5937b4173dabf46a3bcf9ae469a3e1dfb22daa6dfeae1f841095f68ed440076c051be481ec3170eca70fe9092f12574903551c57b4bc1d31e3a9ef2db58aad18d584b547163aa7021472c2208e828d39c009541e7e778ce04b97da34ba \
#       1000

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

NODE_ID="${1:-}"
BLS_PUBLIC_KEY="${2:-}"
BLS_POP="${3:-}"
WEIGHT="${4:-1000}"

check_args() {
    echo "Step: check_args"
    if [ -z "${NODE_ID}" ]; then
        echo "Error: NODE_ID is required."
        echo ""
        echo "Usage: ./06-add-validator.sh <node-id> [bls-public-key] [bls-pop] [weight]"
        echo ""
        echo "To get the NodeID and BLS keys from a running node:"
        echo '  curl -s -X POST --data '"'"'{"jsonrpc":"2.0","method":"info.getNodeID","params":{},"id":1}'"'"' \'
        echo '    -H "Content-Type: application/json" http://127.0.0.1:9650/ext/info | python3 -m json.tool'
        exit 1
    fi
}

add_validator() {
    echo ""
    echo "Step: add_validator"
    echo "Adding validator to ${NETWORK_DISPLAY}..."
    echo ""
    echo "  NodeID:         ${NODE_ID}"
    echo "  Weight:         ${WEIGHT}"

    CMD="avalanche blockchain addValidator ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG}"
    CMD="${CMD} --node-id ${NODE_ID}"
    CMD="${CMD} --weight ${WEIGHT}"

    if [ -n "${BLS_PUBLIC_KEY}" ]; then
        CMD="${CMD} --bls-public-key ${BLS_PUBLIC_KEY}"
        echo "  BLS Public Key: ${BLS_PUBLIC_KEY:0:20}..."
    fi
    if [ -n "${BLS_POP}" ]; then
        CMD="${CMD} --bls-proof-of-possession ${BLS_POP}"
        echo "  BLS PoP:        ${BLS_POP:0:20}..."
    fi

    echo ""
    echo "Running: ${CMD}"
    echo ""

    eval "${CMD}"
}

verify_validator() {
    echo ""
    echo "Step: verify_validator"
    echo "Verifying validator was added..."

    VALIDATORS_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getCurrentValidators\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
validators = d.get('result', {}).get('validators', [])
target = '${NODE_ID}'
found = False
for v in validators:
    if v.get('nodeID') == target:
        print(f'  Validator {target} is ACTIVE (weight: {v.get(\"weight\", \"N/A\")})')
        found = True
        break
if not found:
    print(f'  Validator {target} not found in current validator set.')
    print(f'  It may take a few minutes to appear. Run ./05-verify-conversion.sh to check.')
print(f'  Total validators: {len(validators)}')
" 2>/dev/null
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  Run ./05-verify-conversion.sh to see the full validator set"
}

main() {
    show_configs
    echo ""
    check_args
    add_validator
    verify_validator
    show_next_action_reminder
}

main

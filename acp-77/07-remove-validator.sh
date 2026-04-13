#!/bin/bash
#
# ACP-77: Remove an L1 validator (post-conversion)
#
# Removes a validator from the L1 via the ValidatorManager contract.
#
# Prerequisites:
#   - Subnet converted to L1 and ValidatorManager initialized
#   - At least one other validator must remain active
#
# Usage:
#   ./07-remove-validator.sh <node-id>
#
# Example:
#   ./07-remove-validator.sh NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

NODE_ID="${1:-}"

check_args() {
    echo "Step: check_args"
    if [ -z "${NODE_ID}" ]; then
        echo "Error: NODE_ID is required."
        echo ""
        echo "Usage: ./07-remove-validator.sh <node-id>"
        echo ""
        echo "Run ./05-verify-conversion.sh to see current validators."
        exit 1
    fi
}

check_validator_count() {
    echo "Step: check_validator_count"

    VALIDATORS_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getCurrentValidators\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    VALIDATOR_COUNT=$(echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
validators = d.get('result', {}).get('validators', [])
print(len(validators))
" 2>/dev/null || echo "0")

    echo "  Current validator count: ${VALIDATOR_COUNT}"

    if [ "${VALIDATOR_COUNT}" -le 1 ]; then
        echo ""
        echo "Error: Cannot remove the last validator. The network needs at least one."
        exit 1
    fi
}

confirm_removal() {
    echo ""
    echo "============================================"
    echo "  WARNING: Removing Validator"
    echo "============================================"
    echo ""
    echo "  Network: ${NETWORK_DISPLAY}"
    echo "  NodeID:  ${NODE_ID}"
    echo ""
    read -p "Type 'REMOVE' to proceed: " CONFIRM
    if [ "${CONFIRM}" != "REMOVE" ]; then
        echo "Aborted."
        exit 1
    fi
}

remove_validator() {
    echo ""
    echo "Step: remove_validator"
    echo "Running: avalanche blockchain removeValidator ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG} --node-id ${NODE_ID}"
    echo ""

    avalanche blockchain removeValidator "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG} --node-id "${NODE_ID}"
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  Run ./05-verify-conversion.sh to verify the validator was removed"
}

main() {
    show_configs
    echo ""
    check_args
    check_validator_count
    confirm_removal
    remove_validator
    show_next_action_reminder
}

main

#!/bin/bash
#
# ACP-77 Phase 3: Initialize ValidatorManager contract
#
# After ConvertSubnetToL1Tx is executed, this script initializes the
# ValidatorManager contract with the conversion message from the P-Chain.
#
# Prerequisites:
#   - Subnet successfully converted to L1 (./03-convert-to-l1.sh)
#
# Usage:
#   ./04-init-validator-manager.sh                  # Testnet (default)
#   NETWORK=mainnet ./04-init-validator-manager.sh  # Mainnet

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

check_conversion_status() {
    echo "Step: check_conversion_status"
    echo "Verifying subnet has been converted..."

    SUBNET_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getSubnet\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    IS_PERMISSIONED=$(echo "${SUBNET_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['isPermissioned'])" 2>/dev/null || echo "unknown")

    if [ "${IS_PERMISSIONED}" = "True" ] || [ "${IS_PERMISSIONED}" = "true" ]; then
        echo "Error: Subnet is still permissioned. Run ./03-convert-to-l1.sh first."
        exit 1
    fi

    echo "  Subnet conversion confirmed (isPermissioned: ${IS_PERMISSIONED})"
}

init_validator_manager() {
    echo ""
    echo "Step: init_validator_manager"
    echo "Running: avalanche contract initValidatorManager ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG}"
    echo ""
    echo "This will:"
    echo "  - Read the SubnetToL1ConversionMessage from the P-Chain"
    echo "  - Call initializeValidatorSet() on the ValidatorManager contract"
    echo "  - Register the initial validator set on-chain"
    echo ""

    avalanche contract initValidatorManager "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG}
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  1. Run ./05-verify-conversion.sh to verify everything is working"
    echo "  2. Run ./06-add-validator.sh to add additional validators"
}

main() {
    show_configs
    echo ""
    check_conversion_status
    init_validator_manager
    show_next_action_reminder
}

main

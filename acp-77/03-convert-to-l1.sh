#!/bin/bash
#
# ACP-77 Phase 1-2: Convert Subnet to L1
#
# Executes the ConvertSubnetToL1Tx on the P-Chain. This is IRREVERSIBLE.
# After conversion:
#   - AddSubnetValidatorTx is permanently disabled
#   - Validator management moves to the ValidatorManager contract
#
# Prerequisites:
#   - Avalanche CLI installed (./00-install-avalanche-cli.sh)
#   - Blockchain imported (./01-import-blockchain.sh)
#   - Nodes backed up (./02-backup-node.sh)
#   - ValidatorManager deployed (./02b-deploy-validator-manager.sh)
#   - Subnet owner private key available (or Ledger)
#   - P-Chain has sufficient AVAX balance (~1-2 AVAX)
#
# Note: This script uses 'avalanche blockchain convert' (not 'deploy').
#       'deploy' is for new blockchains and rejects imported ones.
#       'convert' is specifically for upgrading existing subnets to L1.
#
# Usage:
#   ./03-convert-to-l1.sh                  # Convert testnet (default)
#   NETWORK=mainnet ./03-convert-to-l1.sh  # Convert mainnet

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

check_prerequisites() {
    echo "Step: check_prerequisites"

    # Check Avalanche CLI
    if ! command -v avalanche &> /dev/null; then
        echo "Error: Avalanche CLI not found. Run ./00-install-avalanche-cli.sh first."
        exit 1
    fi
    echo "  Avalanche CLI: $(avalanche --version 2>&1 | head -1)"

    # Check P-Chain balance
    echo "  Checking P-Chain balance..."
    BALANCE_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getBalance\",
        \"params\":{\"addresses\":[\"${P_CHAIN_ADDRESS}\"]},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    BALANCE=$(echo "${BALANCE_RESULT}" | python3 -c "import json,sys; print(int(json.load(sys.stdin)['result']['balance'])/1e9)" 2>/dev/null || echo "unknown")
    echo "  P-Chain balance: ${BALANCE} AVAX"

    # Check current subnet status
    echo "  Checking current subnet status..."
    SUBNET_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getSubnet\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    IS_PERMISSIONED=$(echo "${SUBNET_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['isPermissioned'])" 2>/dev/null || echo "unknown")
    echo "  isPermissioned: ${IS_PERMISSIONED}"

    # Check ValidatorManager deployment
    ADDRESS_FILE="${SCRIPT_DIR}/.validator-manager-address-${NETWORK}"
    if [ -f "${ADDRESS_FILE}" ]; then
        VM_ADDRESS=$(cat "${ADDRESS_FILE}")
        echo "  ValidatorManager: ${VM_ADDRESS} (from 02b-deploy-validator-manager.sh)"
    else
        echo "  ValidatorManager: not deployed yet"
        echo ""
        echo "  Hint: Run ./02b-deploy-validator-manager.sh first to deploy the contract."
        echo "  Or you can manually enter the address when prompted by the CLI."
    fi

    if [ "${IS_PERMISSIONED}" = "False" ] || [ "${IS_PERMISSIONED}" = "false" ]; then
        echo ""
        echo "Warning: Subnet is already converted to L1. No conversion needed."
        echo "Run ./05-verify-conversion.sh to check the current state."
        exit 0
    fi
}

confirm_conversion() {
    echo ""
    echo "============================================"
    echo "  WARNING: IRREVERSIBLE OPERATION"
    echo "============================================"
    echo ""
    echo "You are about to convert ${NETWORK_DISPLAY} to an Avalanche L1."
    echo ""
    echo "  Subnet ID:     ${SUBNET_ID}"
    echo "  Blockchain ID: ${BLOCKCHAIN_ID}"
    echo "  Chain Name:    ${CHAIN_NAME}"
    echo "  Network:       ${AVALANCHE_NETWORK}"
    echo ""
    echo "After conversion:"
    echo "  - AddSubnetValidatorTx will be PERMANENTLY DISABLED"
    echo "  - Validator management moves to ValidatorManager contract"
    echo "  - This CANNOT be undone"
    echo ""
    read -p "Type 'CONVERT' to proceed: " CONFIRM
    if [ "${CONFIRM}" != "CONVERT" ]; then
        echo "Aborted."
        exit 1
    fi
}

execute_conversion() {
    echo ""
    echo "Step: execute_conversion"
    echo "Running: avalanche blockchain convert ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG}"
    echo ""
    echo "The CLI will prompt you for:"
    echo "  - ValidatorManager address (use address from 02b-deploy-validator-manager.sh)"
    echo "  - Subnet owner private key (or use --key flag)"
    echo "  - ValidatorManager type (choose PoA for permissioned management)"
    echo "  - PoA owner address (EVM address that controls validators)"
    echo "  - Bootstrap validators (NodeIDs, BLS keys, weights, balances)"
    echo ""
    echo "NOTE: Using 'avalanche blockchain convert' (not 'deploy')."
    echo "      'deploy' creates new blockchains; 'convert' upgrades existing subnets."
    echo ""

    # Pass --validator-manager-address if saved from 02b
    ADDRESS_FILE="${SCRIPT_DIR}/.validator-manager-address-${NETWORK}"
    EXTRA_FLAGS=""
    if [ -f "${ADDRESS_FILE}" ]; then
        VM_ADDRESS=$(cat "${ADDRESS_FILE}")
        echo "Using ValidatorManager address: ${VM_ADDRESS}"
        EXTRA_FLAGS="--validator-manager-address ${VM_ADDRESS}"
    fi

    # shellcheck disable=SC2086
    avalanche blockchain convert "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG} ${EXTRA_FLAGS}
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  1. Run ./04-init-validator-manager.sh to initialize the ValidatorManager"
    echo "  2. Run ./05-verify-conversion.sh to verify the conversion"
}

main() {
    show_configs
    echo ""
    check_prerequisites
    confirm_conversion
    execute_conversion
    show_next_action_reminder
}

main

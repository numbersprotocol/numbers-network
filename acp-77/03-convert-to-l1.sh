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
#   - PoA controller key imported into Avalanche CLI (this script will guide you)
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

# Check for existing subnet validators that would conflict with ConvertSubnetToL1Tx.
# The same NodeID cannot be both a subnet validator and an L1 bootstrap validator.
# Existing validators must be removed before conversion.
check_existing_validators() {
    echo ""
    echo "Step: check_existing_validators"
    echo "  Checking existing subnet validators..."

    VALIDATORS_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getCurrentValidators\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    VALIDATOR_COUNT=$(echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
validators = data.get('result', {}).get('validators', [])
print(len(validators))
" 2>/dev/null || echo "0")

    if [ "${VALIDATOR_COUNT}" = "0" ]; then
        echo "  No existing subnet validators. Ready to convert."
        return
    fi

    # Display existing validators
    echo ""
    echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys
from datetime import datetime, timezone
data = json.load(sys.stdin)
validators = data.get('result', {}).get('validators', [])
print(f'  Found {len(validators)} existing subnet validator(s):')
print()
for v in validators:
    end_ts = int(v['endTime'])
    end_dt = datetime.fromtimestamp(end_ts, tz=timezone.utc)
    now = datetime.now(tz=timezone.utc)
    remaining = end_dt - now
    print(f'    NodeID:   {v[\"nodeID\"]}')
    print(f'    Weight:   {v[\"weight\"]}')
    print(f'    End time: {end_dt.strftime(\"%Y-%m-%d %H:%M UTC\")} ({remaining.days} days remaining)')
    print()
"

    echo "  ============================================"
    echo "  Existing Validators Must Be Removed"
    echo "  ============================================"
    echo ""
    echo "  ConvertSubnetToL1Tx will fail with 'conflicting subnetID + nodeID pair'"
    echo "  if any bootstrap validator NodeID is already an active subnet validator."
    echo ""
    echo "  Remove each validator before converting:"
    echo ""

    # Extract NodeIDs and show removal commands
    echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
validators = data.get('result', {}).get('validators', [])
for v in validators:
    print(f'    avalanche blockchain removeValidator {\"${CHAIN_NAME}\"} ${AVALANCHE_NETWORK_FLAG} --node-id {v[\"nodeID\"]}')
"

    echo ""
    echo "  After removing all validators, re-run this script."
    echo "  ============================================"
    exit 1
}

# Ensure the user has a key imported into Avalanche CLI for PoA controller.
# The CLI ships with only "ewoq" (a well-known test-only key). For real
# networks, the user must import their own key first.
#
# Note: We check the key directory directly instead of running
# "avalanche key list", because that command may hang waiting for
# interactive network selection (to query balances).
ensure_cli_key() {
    echo ""
    echo "Step: ensure_cli_key"
    echo "  Checking Avalanche CLI stored keys..."

    CLI_KEY_DIR="${HOME}/.avalanche-cli/key"

    # Check if any key file other than ewoq exists
    HAS_CUSTOM_KEY=false
    if [ -d "${CLI_KEY_DIR}" ]; then
        for keyfile in "${CLI_KEY_DIR}"/*.pk; do
            [ -f "${keyfile}" ] || continue
            KEYNAME=$(basename "${keyfile}" .pk)
            if [ "${KEYNAME}" != "ewoq" ]; then
                echo "  Found key: ${KEYNAME}"
                HAS_CUSTOM_KEY=true
            fi
        done
    fi

    if [ "${HAS_CUSTOM_KEY}" = "false" ]; then
        echo ""
        echo "============================================"
        echo "  Key Import Required"
        echo "============================================"
        echo ""
        echo "  The CLI only has the built-in 'ewoq' key, which is a well-known"
        echo "  test key (0x8db97C...BF52FC) and must NOT be used on real networks."
        echo ""
        echo "  You need to import the private key that will control the PoA"
        echo "  ValidatorManager (add/remove validators)."
        echo ""
        echo "  Steps to import your key:"
        echo ""
        echo "    # 1. Save your hex private key (without 0x prefix) to a file"
        echo "    echo 'YOUR_PRIVATE_KEY_HEX' > /tmp/poa-controller.pk"
        echo ""
        echo "    # 2. Import it into the CLI"
        echo "    avalanche key create poa-controller --file /tmp/poa-controller.pk"
        echo ""
        echo "    # 3. Verify import"
        echo "    avalanche key list"
        echo ""
        echo "    # 4. Clean up the key file"
        echo "    rm /tmp/poa-controller.pk"
        echo ""
        echo "  Then re-run this script."
        echo "============================================"
        exit 1
    fi

    echo "  Custom key found. You can select it when prompted by the CLI."
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
    check_existing_validators
    ensure_cli_key
    confirm_conversion
    execute_conversion
    show_next_action_reminder
}

main

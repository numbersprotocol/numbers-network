#!/bin/bash
#
# ACP-77 Phase 3: Initialize ValidatorManager contract
#
# After ConvertSubnetToL1Tx is executed, this script initializes the
# ValidatorManager contract with the conversion message from the P-Chain.
#
# The Avalanche CLI's "contract initValidatorManager" sends internal
# transactions with a hardcoded gas price of 225 gwei. Numbers Network
# has minBaseFee = 750 gwei, so these transactions are rejected.
#
# This script works around the issue by:
#   1. Temporarily lowering minBaseFee via FeeConfigManager precompile
#   2. Running "avalanche contract initValidatorManager"
#   3. Restoring minBaseFee to the original value
#
# Prerequisites:
#   - Subnet successfully converted to L1 (./03-convert-to-l1.sh)
#   - Foundry installed (cast command)
#   - DEPLOYER_KEY set (must have FeeConfigManager Admin role)
#   - Avalanche CLI installed
#
# Usage:
#   DEPLOYER_KEY=0x... ./04-init-validator-manager.sh          # Testnet
#   DEPLOYER_KEY=0x... NETWORK=mainnet ./04-init-validator-manager.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

# Precompile addresses
FEE_CONFIG_MANAGER="0x0200000000000000000000000000000000000003"

# Function selectors (first 4 bytes of keccak256 of function signature)
GET_FEE_CONFIG="0x5fbbc0d2"

# CLI's hardcoded gas price for ProposerVM activation
CLI_GAS_PRICE=225000000000  # 225 gwei

# ---------- Checks ----------

check_deployer_key() {
    if [ -z "${DEPLOYER_KEY}" ]; then
        echo "Error: DEPLOYER_KEY environment variable is required."
        echo ""
        echo "Set it to a private key with FeeConfigManager Admin role:"
        echo "  DEPLOYER_KEY=0xYOUR_PRIVATE_KEY ./04-init-validator-manager.sh"
        exit 1
    fi
}

check_cast() {
    if ! command -v cast &> /dev/null; then
        echo "Error: 'cast' (Foundry) not found. Install Foundry first:"
        echo "  curl -L https://foundry.paradigm.xyz | bash && foundryup"
        exit 1
    fi
}

check_avalanche_cli() {
    if ! command -v avalanche &> /dev/null; then
        echo "Error: Avalanche CLI not found. Run ./00-install-avalanche-cli.sh first."
        exit 1
    fi
}

check_conversion_status() {
    echo "Step: check_conversion_status"
    echo "  Verifying subnet has been converted..."

    SUBNET_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getSubnet\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    IS_PERMISSIONED=$(echo "${SUBNET_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['isPermissioned'])" 2>/dev/null || echo "unknown")

    if [ "${IS_PERMISSIONED}" = "True" ] || [ "${IS_PERMISSIONED}" = "true" ]; then
        echo "  Error: Subnet is still permissioned. Run ./03-convert-to-l1.sh first."
        exit 1
    fi

    echo "  Subnet conversion confirmed (isPermissioned: ${IS_PERMISSIONED})"
}

# ---------- Fee Config Helpers ----------

# Read current fee config from FeeConfigManager precompile.
# Outputs 8 space-separated decimal values.
read_fee_config() {
    local RESULT
    RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"eth_call\",
        \"params\":[{
            \"to\":\"${FEE_CONFIG_MANAGER}\",
            \"data\":\"${GET_FEE_CONFIG}\"
        }, \"latest\"],
        \"id\":1
    }" -H 'Content-Type: application/json' "${RPC_URL}")

    echo "${RESULT}" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if 'error' in data:
    print(f'ERROR: {data[\"error\"][\"message\"]}', file=sys.stderr)
    sys.exit(1)
hex_data = data['result'][2:]
values = []
for i in range(8):
    values.append(str(int(hex_data[i*64:(i+1)*64], 16)))
print(' '.join(values))
"
}

# Display fee config in a readable format
show_fee_config() {
    local LABEL="$1"
    shift
    local VALUES=($@)
    local LABELS=(gasLimit targetBlockRate minBaseFee targetGas baseFeeChangeDenominator minBlockGasCost maxBlockGasCost blockGasCostStep)

    echo "  ${LABEL}:"
    for i in "${!LABELS[@]}"; do
        local VAL="${VALUES[$i]}"
        if [ "${LABELS[$i]}" = "minBaseFee" ]; then
            local GWEI
            GWEI=$(python3 -c "print(f'{int(${VAL})/1e9:.1f}')")
            echo "    ${LABELS[$i]}: ${VAL} (${GWEI} gwei)"
        else
            echo "    ${LABELS[$i]}: ${VAL}"
        fi
    done
}

# Set fee config via FeeConfigManager precompile.
# Args: gasLimit targetBlockRate minBaseFee targetGas baseFeeChangeDenom
#       minBlockGasCost maxBlockGasCost blockGasCostStep gasPrice
set_fee_config() {
    local GAS_PRICE_GWEI="$9"
    cast send "${FEE_CONFIG_MANAGER}" \
        "setFeeConfig(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" \
        "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --gas-price "${GAS_PRICE_GWEI}"
}

# ---------- Main ----------

main() {
    show_configs
    echo ""
    check_deployer_key
    check_cast
    check_avalanche_cli
    check_conversion_status

    # Read current fee config
    echo ""
    echo "Step: read_fee_config"
    local CURRENT_CONFIG
    CURRENT_CONFIG=$(read_fee_config)
    local CONFIG_ARRAY=(${CURRENT_CONFIG})
    local ORIGINAL_MIN_BASE_FEE="${CONFIG_ARRAY[2]}"

    show_fee_config "Current fee config" ${CURRENT_CONFIG}

    local ORIGINAL_GWEI
    ORIGINAL_GWEI=$(python3 -c "print(f'{int(${ORIGINAL_MIN_BASE_FEE})/1e9:.0f}')")
    local CLI_GWEI
    CLI_GWEI=$(python3 -c "print(f'{int(${CLI_GAS_PRICE})/1e9:.0f}')")

    # Check if adjustment is needed
    if [ "${ORIGINAL_MIN_BASE_FEE}" -le "${CLI_GAS_PRICE}" ]; then
        echo ""
        echo "  minBaseFee (${ORIGINAL_GWEI} gwei) <= CLI gas price (${CLI_GWEI} gwei)"
        echo "  No adjustment needed."
        echo ""
        echo "Step: init_validator_manager"
        avalanche contract initValidatorManager "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG}
        echo ""
        echo "Done. ValidatorManager initialized successfully."
        return
    fi

    echo ""
    echo "  minBaseFee (${ORIGINAL_GWEI} gwei) > CLI hardcoded gas price (${CLI_GWEI} gwei)"
    echo "  Will temporarily lower minBaseFee for CLI compatibility."
    echo ""

    # Step 1: Lower minBaseFee
    echo "Step: lower_min_base_fee"
    echo "  Lowering minBaseFee from ${ORIGINAL_GWEI} gwei to ${CLI_GWEI} gwei..."
    set_fee_config \
        "${CONFIG_ARRAY[0]}" "${CONFIG_ARRAY[1]}" "${CLI_GAS_PRICE}" "${CONFIG_ARRAY[3]}" \
        "${CONFIG_ARRAY[4]}" "${CONFIG_ARRAY[5]}" "${CONFIG_ARRAY[6]}" "${CONFIG_ARRAY[7]}" \
        "${ORIGINAL_GWEI}gwei"

    echo "  Waiting for new fee config to take effect..."
    sleep 5

    # Verify the change
    local NEW_CONFIG
    NEW_CONFIG=$(read_fee_config)
    show_fee_config "Updated fee config" ${NEW_CONFIG}
    echo ""

    # Step 2: Run initValidatorManager
    echo "Step: init_validator_manager"
    echo "  Running: avalanche contract initValidatorManager ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG}"
    echo ""

    local INIT_EXIT_CODE=0
    avalanche contract initValidatorManager "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG} || INIT_EXIT_CODE=$?

    echo ""

    # Step 3: Restore minBaseFee (always, even if init failed)
    echo "Step: restore_min_base_fee"
    echo "  Restoring minBaseFee to ${ORIGINAL_GWEI} gwei..."

    # Use a safe gas price for the restore transaction.
    # After lowering minBaseFee, the chain might accept lower gas prices,
    # but we use the original value to be safe.
    set_fee_config \
        "${CONFIG_ARRAY[0]}" "${CONFIG_ARRAY[1]}" "${ORIGINAL_MIN_BASE_FEE}" "${CONFIG_ARRAY[3]}" \
        "${CONFIG_ARRAY[4]}" "${CONFIG_ARRAY[5]}" "${CONFIG_ARRAY[6]}" "${CONFIG_ARRAY[7]}" \
        "${ORIGINAL_GWEI}gwei"

    echo "  Waiting for restore to take effect..."
    sleep 5

    # Verify restore
    local RESTORED_CONFIG
    RESTORED_CONFIG=$(read_fee_config)
    show_fee_config "Restored fee config" ${RESTORED_CONFIG}

    echo ""
    if [ "${INIT_EXIT_CODE}" -ne 0 ]; then
        echo "============================================"
        echo "  WARNING: initValidatorManager failed"
        echo "============================================"
        echo "  Exit code: ${INIT_EXIT_CODE}"
        echo "  minBaseFee has been restored to ${ORIGINAL_GWEI} gwei."
        echo "  Check the error above and try again."
        exit "${INIT_EXIT_CODE}"
    fi

    echo "============================================"
    echo "  ValidatorManager Initialized Successfully"
    echo "============================================"
    echo "  minBaseFee restored to ${ORIGINAL_GWEI} gwei."
    echo ""
    echo "Next steps:"
    echo "  1. Run ./05-verify-conversion.sh to verify everything is working"
    echo "  2. Run ./06-add-validator.sh to add additional validators"
}

main

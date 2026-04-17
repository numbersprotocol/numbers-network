#!/bin/bash
#
# ACP-77 Phase 3: Initialize ValidatorManager contract
#
# After ConvertSubnetToL1Tx is executed, this script initializes the
# ValidatorManager contract with the conversion message from the P-Chain.
#
# The Avalanche CLI's "contract initValidatorManager" sends internal
# transactions with a hardcoded gas price of 225 gwei. Numbers Network
# has minBaseFee = 750 gwei, so these transactions are rejected AND the
# actual per-block baseFee is calculated EIP-1559-style from the previous
# block, so simply lowering minBaseFee does NOT immediately lower baseFee.
#
# This script works around the issue by:
#   1. (Recovery) Detect and cancel any stuck pending tx on the deployer
#      account (nonce conflict causes "replacement transaction underpriced"
#      if we skip this step).
#   2. Temporarily lower minBaseFee via FeeConfigManager precompile.
#   3. Force baseFee decay by sending self-transfers at gas prices just
#      above the current baseFee, one block at a time, until baseFee has
#      drifted down to <= 225 gwei (CLI's hardcoded gas price).
#   4. Run "avalanche contract initValidatorManager".
#   5. Restore minBaseFee using a gas price that matches the current
#      baseFee (avoid "replacement underpriced" on restore).
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

# CLI's hardcoded gas price for ProposerVM activation / initValidatorManager
CLI_GAS_PRICE=225000000000  # 225 gwei (wei)
CLI_GAS_PRICE_GWEI=225

# Upper bound for baseFee-decay iterations before giving up.
# EIP-1559 / subnet-evm decays baseFee at most ~1/48 (~2%) per block
# when the block is under the gas target, so going 750 -> 225 takes
# roughly log(225/750) / log(47/48) ~= 57 blocks. Give generous margin.
DECAY_MAX_ITER=120

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
    # Add Foundry bin to PATH if installed but not in PATH
    if ! command -v cast &> /dev/null && [ -d "${HOME}/.foundry/bin" ]; then
        export PATH="${HOME}/.foundry/bin:${PATH}"
    fi

    if ! command -v cast &> /dev/null; then
        echo "  Foundry not found. Installing..."
        curl -L https://foundry.paradigm.xyz | bash
        export PATH="${HOME}/.foundry/bin:${PATH}"
        foundryup
    fi

    if ! command -v cast &> /dev/null; then
        echo "Error: 'cast' (Foundry) installation failed."
        echo "  Try manually: curl -L https://foundry.paradigm.xyz | bash && foundryup"
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
#       minBlockGasCost maxBlockGasCost blockGasCostStep gasPriceArg
# gasPriceArg is passed directly to `cast send --gas-price` (e.g. "750gwei"
# or a wei-denominated integer).
set_fee_config() {
    local GAS_PRICE="$9"
    cast send "${FEE_CONFIG_MANAGER}" \
        "setFeeConfig(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" \
        "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --gas-price "${GAS_PRICE}"
}

# ---------- Chain State Helpers ----------

get_base_fee_wei() {
    curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' \
        -H 'Content-Type: application/json' "${RPC_URL}" | \
        python3 -c "import json,sys; print(int(json.load(sys.stdin)['result']['baseFeePerGas'],16))"
}

get_block_number() {
    curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        -H 'Content-Type: application/json' "${RPC_URL}" | \
        python3 -c "import json,sys; print(int(json.load(sys.stdin)['result'],16))"
}

get_nonce() {
    # $1 = "latest" | "pending"
    curl -s -X POST --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_getTransactionCount\",\"params\":[\"${DEPLOYER_ADDR}\",\"$1\"],\"id\":1}" \
        -H 'Content-Type: application/json' "${RPC_URL}" | \
        python3 -c "import json,sys; print(int(json.load(sys.stdin)['result'],16))"
}

# Send a 0-value self-transfer. Used for:
#   - cancelling a stuck pending tx (pass --nonce via $2 == nonce)
#   - pushing a block to force baseFee decay (leave $2 empty)
# $1 = gas price (wei integer or "<N>gwei")
# $2 = optional explicit nonce
#
# Uses EIP-1559 params (--gas-price as maxFeePerGas, --priority-gas-price
# as maxPriorityFeePerGas) set to the SAME value, which makes the tx look
# like a strict fixed-price tx and ensures replacement rules are satisfied
# against EITHER legacy or 1559 pending txs.
send_self_tx() {
    local GAS_PRICE="$1"
    local EXPLICIT_NONCE="$2"
    if [ -n "${EXPLICIT_NONCE}" ]; then
        cast send "${DEPLOYER_ADDR}" \
            --value 0 \
            --nonce "${EXPLICIT_NONCE}" \
            --gas-price "${GAS_PRICE}" \
            --priority-gas-price "${GAS_PRICE}" \
            --rpc-url "${RPC_URL}" \
            --private-key "${DEPLOYER_KEY}"
    else
        cast send "${DEPLOYER_ADDR}" \
            --value 0 \
            --gas-price "${GAS_PRICE}" \
            --priority-gas-price "${GAS_PRICE}" \
            --rpc-url "${RPC_URL}" \
            --private-key "${DEPLOYER_KEY}"
    fi
}

# ---------- Recovery: cancel any stuck pending tx ----------

recover_stuck_tx() {
    echo "Step: recover_stuck_tx"
    local LATEST PENDING
    LATEST=$(get_nonce latest)
    PENDING=$(get_nonce pending)
    echo "  Deployer: ${DEPLOYER_ADDR}"
    echo "  Mined nonce (latest):   ${LATEST}"
    echo "  Pending nonce:          ${PENDING}"

    if [ "${PENDING}" -le "${LATEST}" ]; then
        echo "  No stuck tx. Proceeding."
        return 0
    fi

    local STUCK=${LATEST}
    local BASE_FEE_WEI
    BASE_FEE_WEI=$(get_base_fee_wei)
    echo "  Stuck pending tx at nonce ${STUCK}."
    echo "  Current baseFee: $(python3 -c "print(f'{${BASE_FEE_WEI}/1e9:.1f}')") gwei"

    # We don't know the stuck tx's exact gas params (it could be legacy or
    # EIP-1559, with an arbitrarily large maxFeePerGas buffer). Geth's
    # replacement rule requires BOTH new gasTipCap and gasFeeCap to exceed
    # the old values by >= 10%. Try progressively higher multipliers until
    # replacement succeeds or we hit the ceiling.
    local MULTIPLIERS=(3 10 30 100 300 1000)
    local SUCCESS=0
    for MULT in "${MULTIPLIERS[@]}"; do
        local REPLACE_WEI
        REPLACE_WEI=$(python3 -c "print(int(${BASE_FEE_WEI} * ${MULT}))")
        local REPLACE_GWEI
        REPLACE_GWEI=$(python3 -c "print(f'{${REPLACE_WEI}/1e9:.1f}')")

        echo "  Trying replacement at ${REPLACE_GWEI} gwei (${MULT}x baseFee)..."
        local ERR_LOG
        ERR_LOG=$(mktemp)
        if send_self_tx "${REPLACE_WEI}" "${STUCK}" 2> "${ERR_LOG}"; then
            SUCCESS=1
            rm -f "${ERR_LOG}"
            break
        fi

        if grep -qi "underpriced" "${ERR_LOG}"; then
            echo "    still underpriced, bumping further..."
            rm -f "${ERR_LOG}"
            continue
        fi

        # Different error - surface it and abort
        echo "  Error during replacement:"
        cat "${ERR_LOG}"
        rm -f "${ERR_LOG}"
        exit 1
    done

    if [ "${SUCCESS}" -ne 1 ]; then
        echo "  Error: could not replace stuck tx even at 1000x baseFee."
        echo "  The stuck tx has an unusually high maxFeePerGas."
        echo "  You may need to wait or manually craft a replacement."
        exit 1
    fi

    # Confirm chain advanced
    local NEW_LATEST
    NEW_LATEST=$(get_nonce latest)
    if [ "${NEW_LATEST}" -le "${LATEST}" ]; then
        echo "  Waiting for replacement to mine..."
        sleep 5
        NEW_LATEST=$(get_nonce latest)
    fi

    if [ "${NEW_LATEST}" -le "${LATEST}" ]; then
        echo "  Error: replacement accepted but not yet mined. Re-run the script."
        exit 1
    fi

    echo "  Stuck tx cleared (mined nonce now ${NEW_LATEST})."
}

# ---------- BaseFee Decay ----------

# Send self-transfers until the chain's baseFee drops to <= target (in wei).
# Each tx mines a new block and lets EIP-1559 lower baseFee by up to 1/denom.
decay_base_fee_to() {
    local TARGET_WEI="$1"
    local TARGET_GWEI
    TARGET_GWEI=$(python3 -c "print(f'{${TARGET_WEI}/1e9:.0f}')")

    echo "Step: decay_base_fee_to"
    echo "  Target baseFee: <= ${TARGET_GWEI} gwei"

    local i=0
    while [ $i -lt ${DECAY_MAX_ITER} ]; do
        local BASE_WEI
        BASE_WEI=$(get_base_fee_wei)
        local BASE_GWEI
        BASE_GWEI=$(python3 -c "print(f'{${BASE_WEI}/1e9:.2f}')")

        if [ "${BASE_WEI}" -le "${TARGET_WEI}" ]; then
            echo "  [${i}] baseFee=${BASE_GWEI} gwei <= ${TARGET_GWEI} gwei. Decay complete."
            return 0
        fi

        # Gas price: baseFee * 1.05 rounded up (must be >= current baseFee
        # AND >= minBaseFee). Integer math via python3 to avoid bash limits.
        local GAS_WEI
        GAS_WEI=$(python3 -c "print(int(${BASE_WEI} * 105 // 100) + 1)")
        local GAS_GWEI
        GAS_GWEI=$(python3 -c "print(f'{${GAS_WEI}/1e9:.2f}')")

        echo "  [${i}] baseFee=${BASE_GWEI} gwei, sending self-tx at ${GAS_GWEI} gwei..."
        if ! send_self_tx "${GAS_WEI}" "" > /dev/null 2>&1; then
            echo "       (tx submission failed; retrying after 2s)"
            sleep 2
        fi

        i=$((i + 1))
    done

    echo "  Error: baseFee did not decay to ${TARGET_GWEI} gwei after ${DECAY_MAX_ITER} iterations."
    return 1
}

# ---------- Main ----------

main() {
    show_configs
    echo ""
    check_deployer_key
    check_cast
    check_avalanche_cli

    # Derive deployer address from private key (needed for nonce lookups).
    DEPLOYER_ADDR=$(cast wallet address --private-key "${DEPLOYER_KEY}")
    echo "  Deployer address: ${DEPLOYER_ADDR}"
    echo ""

    check_conversion_status
    echo ""

    # Recovery path: clear any stuck pending tx before we touch nonces.
    recover_stuck_tx
    echo ""

    # Read current fee config
    echo "Step: read_fee_config"
    local CURRENT_CONFIG
    CURRENT_CONFIG=$(read_fee_config)
    local CONFIG_ARRAY=(${CURRENT_CONFIG})
    local ORIGINAL_MIN_BASE_FEE="${CONFIG_ARRAY[2]}"

    show_fee_config "Current fee config" ${CURRENT_CONFIG}

    local ORIGINAL_GWEI
    ORIGINAL_GWEI=$(python3 -c "print(f'{int(${ORIGINAL_MIN_BASE_FEE})/1e9:.0f}')")

    echo ""

    # If minBaseFee is already <= CLI gas price, we may only need to drive
    # the current baseFee down (no config change needed).
    if [ "${ORIGINAL_MIN_BASE_FEE}" -gt "${CLI_GAS_PRICE}" ]; then
        echo "Step: lower_min_base_fee"
        echo "  minBaseFee (${ORIGINAL_GWEI} gwei) > CLI gas price (${CLI_GAS_PRICE_GWEI} gwei)"
        echo "  Lowering minBaseFee to ${CLI_GAS_PRICE_GWEI} gwei..."

        # Pick a gas price that is >= current baseFee for the setFeeConfig
        # tx itself (so it mines immediately). Use 2x current baseFee.
        local NOW_BASE_WEI
        NOW_BASE_WEI=$(get_base_fee_wei)
        local SETCFG_GAS_WEI
        SETCFG_GAS_WEI=$(python3 -c "print(int(${NOW_BASE_WEI} * 2))")

        set_fee_config \
            "${CONFIG_ARRAY[0]}" "${CONFIG_ARRAY[1]}" "${CLI_GAS_PRICE}" "${CONFIG_ARRAY[3]}" \
            "${CONFIG_ARRAY[4]}" "${CONFIG_ARRAY[5]}" "${CONFIG_ARRAY[6]}" "${CONFIG_ARRAY[7]}" \
            "${SETCFG_GAS_WEI}"

        sleep 2

        local NEW_CONFIG
        NEW_CONFIG=$(read_fee_config)
        show_fee_config "Updated fee config" ${NEW_CONFIG}
        echo ""
    else
        echo "  minBaseFee (${ORIGINAL_GWEI} gwei) already <= CLI gas price"
        echo "  (${CLI_GAS_PRICE_GWEI} gwei). Skipping minBaseFee lowering."
        echo ""
    fi

    # Drive actual baseFee down to CLI gas price (225 gwei) by mining
    # self-transfer blocks. Subnet-EVM produces blocks on-demand, so CLI's
    # 225-gwei txs would otherwise sit in the mempool forever.
    decay_base_fee_to "${CLI_GAS_PRICE}"
    echo ""

    # Run initValidatorManager
    #
    # IMPORTANT: the CLI calls GetCurrentL1Epoch which first tries ProposerVM
    # Connect-RPC, then falls back to JSON-RPC at
    # {rpc_host}/ext/bc/{blockchainID}/proposervm. Public RPC gateways
    # typically do NOT expose proposervm routes and return 404, failing with
    # "failure getting p-chain height: received status code: 404". Point the
    # CLI at a direct validator endpoint (CLI_RPC_URL from env.sh) so the
    # JSON-RPC fallback succeeds.
    local CLI_RPC_FLAG=""
    if [ -n "${CLI_RPC_URL}" ]; then
        CLI_RPC_FLAG="--rpc ${CLI_RPC_URL}"
        echo "Step: init_validator_manager"
        echo "  Using CLI RPC endpoint: ${CLI_RPC_URL}"
        echo "  (public RPC does not expose ProposerVM JSON-RPC; validator direct does)"
    else
        echo "Step: init_validator_manager"
        echo "  Using default RPC (from sidecar)"
    fi
    echo "  Running: avalanche contract initValidatorManager ${CHAIN_NAME} ${AVALANCHE_NETWORK_FLAG} ${CLI_RPC_FLAG}"
    echo ""

    local INIT_EXIT_CODE=0
    avalanche contract initValidatorManager "${CHAIN_NAME}" ${AVALANCHE_NETWORK_FLAG} ${CLI_RPC_FLAG} || INIT_EXIT_CODE=$?

    echo ""

    # Restore minBaseFee (always, even if init failed) — only if we changed
    # it in the first place.
    if [ "${ORIGINAL_MIN_BASE_FEE}" -gt "${CLI_GAS_PRICE}" ]; then
        echo "Step: restore_min_base_fee"
        echo "  Restoring minBaseFee to ${ORIGINAL_GWEI} gwei..."

        # Pick a gas price >= current baseFee AND above any potential
        # in-flight tx. Use 3x current baseFee.
        local POST_BASE_WEI
        POST_BASE_WEI=$(get_base_fee_wei)
        local RESTORE_GAS_WEI
        RESTORE_GAS_WEI=$(python3 -c "print(int(${POST_BASE_WEI} * 3))")

        # Also ensure we're using the next free nonce (CLI may have left
        # pending entries if it errored).
        local LATEST_NONCE PENDING_NONCE
        LATEST_NONCE=$(get_nonce latest)
        PENDING_NONCE=$(get_nonce pending)
        if [ "${PENDING_NONCE}" -gt "${LATEST_NONCE}" ]; then
            echo "  Warning: ${PENDING_NONCE} - ${LATEST_NONCE} pending tx(s) on deployer."
            echo "  Clearing them with a high-gas self-transfer before restore..."
            send_self_tx "${RESTORE_GAS_WEI}" "${LATEST_NONCE}" || true
            sleep 2
        fi

        set_fee_config \
            "${CONFIG_ARRAY[0]}" "${CONFIG_ARRAY[1]}" "${ORIGINAL_MIN_BASE_FEE}" "${CONFIG_ARRAY[3]}" \
            "${CONFIG_ARRAY[4]}" "${CONFIG_ARRAY[5]}" "${CONFIG_ARRAY[6]}" "${CONFIG_ARRAY[7]}" \
            "${RESTORE_GAS_WEI}"

        sleep 2

        local RESTORED_CONFIG
        RESTORED_CONFIG=$(read_fee_config)
        show_fee_config "Restored fee config" ${RESTORED_CONFIG}
    fi

    echo ""
    if [ "${INIT_EXIT_CODE}" -ne 0 ]; then
        echo "============================================"
        echo "  WARNING: initValidatorManager failed"
        echo "============================================"
        echo "  Exit code: ${INIT_EXIT_CODE}"
        echo "  Check the error above and re-run this script."
        echo "  (The recovery step at the top will unstick any pending tx.)"
        exit "${INIT_EXIT_CODE}"
    fi

    echo "============================================"
    echo "  ValidatorManager Initialized Successfully"
    echo "============================================"
    echo ""
    echo "Next steps:"
    echo "  1. Run ./05-verify-conversion.sh to verify everything is working"
    echo "  2. Run ./06-add-validator.sh to add additional validators"
}

main

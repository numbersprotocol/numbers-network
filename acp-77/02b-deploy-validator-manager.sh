#!/bin/bash
#
# ACP-77 Phase 1: Deploy ValidatorManager contract
#
# Deploys the ValidatorManager smart contract (behind a proxy) onto the
# L1 chain. The proxy address is needed by 03-convert-to-l1.sh when
# executing ConvertSubnetToL1Tx.
#
# Contracts deployed (from ava-labs/icm-services):
#   1. ValidatorMessages   — Library for P-Chain message encoding
#   2. ValidatorManager    — Implementation contract (ACP-99 compliant)
#   3. TransparentUpgradeableProxy — Proxy pointing to ValidatorManager
#      (OpenZeppelin v5: auto-deploys ProxyAdmin)
#
# Prerequisites:
#   - Foundry installed (this script can install it)
#   - A private key with tokens on the L1 chain for gas (set DEPLOYER_KEY)
#   - Network RPC reachable
#
# Usage:
#   DEPLOYER_KEY=0x... ./02b-deploy-validator-manager.sh          # Testnet
#   DEPLOYER_KEY=0x... NETWORK=mainnet ./02b-deploy-validator-manager.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

ICM_SERVICES_DIR="${SCRIPT_DIR}/.icm-services"
ICM_SERVICES_REPO="https://github.com/ava-labs/icm-services.git"
ADDRESS_FILE="${SCRIPT_DIR}/.validator-manager-address-${NETWORK}"

# Contract paths (relative to icm-services project root)
# foundry.toml sets src = 'icm-contracts/avalanche/', but forge create
# requires paths relative to the project root.
CONTRACTS_BASE="icm-contracts/avalanche/validator-manager"
VALIDATOR_MESSAGES_SOL="${CONTRACTS_BASE}/ValidatorMessages.sol:ValidatorMessages"
VALIDATOR_MANAGER_SOL="${CONTRACTS_BASE}/ValidatorManager.sol:ValidatorManager"
PROXY_SOL="lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy"

# ---------- Checks ----------

check_deployer_key() {
    if [ -z "${DEPLOYER_KEY}" ]; then
        echo "Error: DEPLOYER_KEY environment variable is required."
        echo ""
        echo "Set it to a private key that has tokens on ${NETWORK_DISPLAY} for gas:"
        echo "  DEPLOYER_KEY=0xYOUR_PRIVATE_KEY ./02b-deploy-validator-manager.sh"
        exit 1
    fi
}

check_existing_deployment() {
    if [ -f "${ADDRESS_FILE}" ]; then
        EXISTING_ADDR=$(cat "${ADDRESS_FILE}")
        echo "Warning: A previous deployment was recorded:"
        echo "  ${EXISTING_ADDR}"
        echo ""
        read -p "Deploy a new contract? (y/N): " CONFIRM
        if [ "${CONFIRM}" != "y" ] && [ "${CONFIRM}" != "Y" ]; then
            echo "Using existing address: ${EXISTING_ADDR}"
            exit 0
        fi
    fi
}

# ---------- Helpers ----------

# Deploy timeout in seconds (Subnet-EVM may have longer block times)
FORGE_TIMEOUT="${FORGE_TIMEOUT:-120}"

# Run forge create and extract the deployed address from text output.
# Does NOT use --json because forge's JSON mode may skip waiting for
# the transaction receipt on some chains (outputs tx data without deployedTo).
# Instead, parses the human-readable "Deployed to: 0x..." line.
forge_create() {
    local LABEL="$1"
    shift

    local TMPFILE
    TMPFILE=$(mktemp)
    trap "rm -f ${TMPFILE}" RETURN

    echo "         Sending transaction..." >&2

    # Run forge create, showing output in real-time (tee) and capturing it.
    # --timeout ensures we wait long enough for Subnet-EVM confirmation.
    if ! forge create "$@" --timeout "${FORGE_TIMEOUT}" 2>&1 | tee "${TMPFILE}"; then
        echo "" >&2
        echo "Error: Failed to deploy ${LABEL}" >&2
        exit 1
    fi

    # Extract "Deployed to: 0x..." from the text output (POSIX-compatible, works on macOS/Linux)
    local ADDRESS
    ADDRESS=$(sed -n 's/.*Deployed to: \(0x[0-9a-fA-F]*\).*/\1/p' "${TMPFILE}" | head -1)

    if [ -z "${ADDRESS}" ]; then
        echo "" >&2
        echo "Error: Could not find 'Deployed to:' in forge output for ${LABEL}" >&2
        echo "This may indicate the transaction was sent but not confirmed." >&2
        echo "Check the deployer nonce and chain explorer." >&2
        exit 1
    fi

    # Only the address goes to stdout (captured by caller)
    echo "${ADDRESS}"
}

# ---------- Setup ----------

install_foundry() {
    echo "Step: install_foundry"
    if command -v forge &> /dev/null; then
        echo "  Foundry already installed: $(forge --version 2>&1 | head -1)"
        return
    fi
    echo "  Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="${HOME}/.foundry/bin:${PATH}"
    foundryup
    echo "  Foundry installed: $(forge --version 2>&1 | head -1)"
}

clone_and_build() {
    echo ""
    echo "Step: clone_and_build"
    if [ -d "${ICM_SERVICES_DIR}" ]; then
        echo "  icm-services already present at ${ICM_SERVICES_DIR}"
    else
        echo "  Cloning ava-labs/icm-services..."
        git clone "${ICM_SERVICES_REPO}" "${ICM_SERVICES_DIR}"
    fi

    cd "${ICM_SERVICES_DIR}"

    echo "  Installing submodules (OpenZeppelin, forge-std, etc.)..."
    git submodule update --init --recursive

    echo "  Building contracts..."
    forge build
    echo "  Build complete."
}

# ---------- Deploy ----------

deploy_contracts() {
    echo ""
    echo "Step: deploy_contracts"
    echo "  RPC: ${RPC_URL}"

    DEPLOYER_ADDRESS=$(cast wallet address "${DEPLOYER_KEY}")
    echo "  Deployer: ${DEPLOYER_ADDRESS}"
    echo ""

    cd "${ICM_SERVICES_DIR}"

    # 1. Deploy ValidatorMessages library
    echo "  [1/3] Deploying ValidatorMessages library..."
    LIB_ADDRESS=$(forge_create "ValidatorMessages" \
        "${VALIDATOR_MESSAGES_SOL}" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}")
    echo "         ValidatorMessages: ${LIB_ADDRESS}"

    # 2. Deploy ValidatorManager implementation (linked with library)
    echo "  [2/3] Deploying ValidatorManager implementation..."
    IMPL_ADDRESS=$(forge_create "ValidatorManager" \
        "${VALIDATOR_MANAGER_SOL}" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --libraries "${CONTRACTS_BASE}/ValidatorMessages.sol:ValidatorMessages:${LIB_ADDRESS}")
    echo "         ValidatorManager:  ${IMPL_ADDRESS}"

    # 3. Deploy TransparentUpgradeableProxy (OpenZeppelin v5)
    #    Constructor: (logic, initialOwner, data)
    #    - initialOwner: becomes the owner of the auto-deployed ProxyAdmin
    #    - data: empty bytes (initialization done later by initValidatorManager)
    echo "  [3/3] Deploying TransparentUpgradeableProxy..."
    PROXY_ADDRESS=$(forge_create "TransparentUpgradeableProxy" \
        "${PROXY_SOL}" \
        --constructor-args "${IMPL_ADDRESS}" "${DEPLOYER_ADDRESS}" "0x" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}")
    echo "         Proxy:             ${PROXY_ADDRESS}"

    # Save the proxy address for 03-convert-to-l1.sh
    echo "${PROXY_ADDRESS}" > "${ADDRESS_FILE}"

    echo ""
    echo "============================================"
    echo "  ValidatorManager Deployed Successfully"
    echo "============================================"
    echo "  Network:                  ${NETWORK_DISPLAY}"
    echo "  ValidatorMessages:        ${LIB_ADDRESS}"
    echo "  ValidatorManager (impl):  ${IMPL_ADDRESS}"
    echo "  Proxy (ValidatorManager): ${PROXY_ADDRESS}"
    echo "============================================"
    echo ""
    echo "  Address saved to: ${ADDRESS_FILE}"
}

show_next_action_reminder() {
    PROXY_ADDRESS=$(cat "${ADDRESS_FILE}")
    echo ""
    echo "Next steps:"
    echo "  1. Run ./03-convert-to-l1.sh"
    echo "     When prompted for 'address of the Validator Manager', enter:"
    echo "     ${PROXY_ADDRESS}"
    echo "  2. Run ./04-init-validator-manager.sh to initialize the contract"
}

# ---------- Main ----------

main() {
    show_configs
    echo ""
    check_deployer_key
    check_existing_deployment
    install_foundry
    clone_and_build
    deploy_contracts
    show_next_action_reminder
}

main

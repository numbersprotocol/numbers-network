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

# Contract paths (relative to icm-services repo root, using foundry src = icm-contracts/avalanche/)
VM_CONTRACTS_DIR="validator-manager"
VALIDATOR_MESSAGES_SOL="${VM_CONTRACTS_DIR}/ValidatorMessages.sol:ValidatorMessages"
VALIDATOR_MANAGER_SOL="${VM_CONTRACTS_DIR}/ValidatorManager.sol:ValidatorManager"
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
        git clone --depth 1 "${ICM_SERVICES_REPO}" "${ICM_SERVICES_DIR}"
    fi

    cd "${ICM_SERVICES_DIR}"

    echo "  Installing dependencies..."
    git submodule update --init --recursive 2>/dev/null || true

    echo "  Building contracts..."
    forge build
    echo "  Build complete."
}

# ---------- Deploy ----------

deploy_contracts() {
    echo ""
    echo "Step: deploy_contracts"
    echo "  RPC: ${RPC_URL}"
    echo "  Deployer: $(cast wallet address "${DEPLOYER_KEY}" 2>/dev/null || echo 'unknown')"
    echo ""

    cd "${ICM_SERVICES_DIR}"

    # 1. Deploy ValidatorMessages library
    echo "  [1/3] Deploying ValidatorMessages library..."
    LIB_RESULT=$(forge create \
        "${VALIDATOR_MESSAGES_SOL}" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --json 2>/dev/null)

    LIB_ADDRESS=$(echo "${LIB_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['deployedTo'])")
    echo "         ValidatorMessages: ${LIB_ADDRESS}"

    # 2. Deploy ValidatorManager implementation (linked with library)
    echo "  [2/3] Deploying ValidatorManager implementation..."
    IMPL_RESULT=$(forge create \
        "${VALIDATOR_MANAGER_SOL}" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --libraries "${VM_CONTRACTS_DIR}/ValidatorMessages.sol:ValidatorMessages:${LIB_ADDRESS}" \
        --json 2>/dev/null)

    IMPL_ADDRESS=$(echo "${IMPL_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['deployedTo'])")
    echo "         ValidatorManager:  ${IMPL_ADDRESS}"

    # 3. Deploy TransparentUpgradeableProxy (OpenZeppelin v5)
    #    Constructor: (logic, initialOwner, data)
    #    - initialOwner: becomes the owner of the auto-deployed ProxyAdmin
    #    - data: empty bytes (initialization done later by initValidatorManager)
    DEPLOYER_ADDRESS=$(cast wallet address "${DEPLOYER_KEY}")

    echo "  [3/3] Deploying TransparentUpgradeableProxy..."
    PROXY_RESULT=$(forge create \
        "${PROXY_SOL}" \
        --constructor-args "${IMPL_ADDRESS}" "${DEPLOYER_ADDRESS}" "0x" \
        --rpc-url "${RPC_URL}" \
        --private-key "${DEPLOYER_KEY}" \
        --json 2>/dev/null)

    PROXY_ADDRESS=$(echo "${PROXY_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['deployedTo'])")
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

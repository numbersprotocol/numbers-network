#!/bin/bash
#
# ACP-77: Shared network configuration for Numbers Network
#
# Usage:
#   source env.sh            # Uses testnet (default)
#   NETWORK=mainnet source env.sh  # Uses mainnet
#
# This file is sourced by all ACP-77 scripts.

# Network selection: testnet (default) or mainnet
NETWORK="${NETWORK:-testnet}"

# Common
AVALANCHEGO_VERSION="1.14.1"
SUBNET_EVM_VERSION="0.8.0"

if [ "${NETWORK}" = "testnet" ]; then
    # Numbers Testnet: Snow (雪)
    NETWORK_DISPLAY="Numbers Testnet (Snow)"
    AVALANCHE_NETWORK="fuji"
    AVALANCHE_NETWORK_FLAG="--fuji"
    CHAIN_ID="10508"
    CHAIN_NAME="captevm"
    SUBNET_ID="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"
    BLOCKCHAIN_ID="2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ"
    VM_ID="kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT"
    RPC_URL="https://testnetrpc.num.network"
    WS_URL="wss://testnetrpc.num.network/ws"
    EXPLORER_URL="https://testnet.num.network"
    P_CHAIN_API="https://api.avax-test.network/ext/bc/P"
    P_CHAIN_ADDRESS="P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk"
    FEE_RECIPIENT="0xE021c9B8DC3953f4f7f286C44a63f5fF001EF481"
elif [ "${NETWORK}" = "mainnet" ]; then
    # Numbers Mainnet: Jade (玉)
    NETWORK_DISPLAY="Numbers Mainnet (Jade)"
    AVALANCHE_NETWORK="mainnet"
    AVALANCHE_NETWORK_FLAG="--mainnet"
    CHAIN_ID="10507"
    CHAIN_NAME="numbersevm"
    SUBNET_ID="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"
    BLOCKCHAIN_ID="2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE"
    VM_ID="qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx"
    RPC_URL="https://mainnetrpc.num.network"
    WS_URL="wss://mainnetrpc.num.network/ws"
    EXPLORER_URL="https://mainnet.num.network"
    P_CHAIN_API="https://api.avax.network/ext/bc/P"
    P_CHAIN_ADDRESS="P-avax142ue2exu7qxuawxe34ww8t623lv82tu2vt573g"
    FEE_RECIPIENT="0xe49a1220eE09Fbf0D25CA9e3BB8D5fD356Fc67FF"
else
    echo "Error: NETWORK must be 'testnet' or 'mainnet', got '${NETWORK}'"
    exit 1
fi

# Avalanchego paths
AVALANCHEGO_HOME="${HOME}/.avalanchego"
AVALANCHEGO_DB_DIR="${AVALANCHEGO_HOME}/db"
AVALANCHEGO_STAKING_DIR="${AVALANCHEGO_HOME}/staking"
AVALANCHEGO_CONFIGS_DIR="${AVALANCHEGO_HOME}/configs"
AVALANCHEGO_LOGS_DIR="${AVALANCHEGO_HOME}/logs"
AVALANCHEGO_PLUGINS_DIR="${AVALANCHEGO_HOME}/plugins"
AVALANCHEGO_BIN_DIR="${HOME}/avalanchego-v${AVALANCHEGO_VERSION}"

show_configs() {
    echo "============================================"
    echo "  ACP-77 Configuration"
    echo "============================================"
    echo "NETWORK:            ${NETWORK_DISPLAY}"
    echo "AVALANCHE_NETWORK:  ${AVALANCHE_NETWORK}"
    echo "CHAIN_ID:           ${CHAIN_ID}"
    echo "CHAIN_NAME:         ${CHAIN_NAME}"
    echo "SUBNET_ID:          ${SUBNET_ID}"
    echo "BLOCKCHAIN_ID:      ${BLOCKCHAIN_ID}"
    echo "VM_ID:              ${VM_ID}"
    echo "RPC_URL:            ${RPC_URL}"
    echo "P_CHAIN_API:        ${P_CHAIN_API}"
    echo "AVALANCHEGO:        v${AVALANCHEGO_VERSION}"
    echo "SUBNET_EVM:         v${SUBNET_EVM_VERSION}"
    echo "============================================"
}

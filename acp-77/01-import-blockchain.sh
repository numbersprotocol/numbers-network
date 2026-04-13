#!/bin/bash
#
# ACP-77 Phase 0: Import existing blockchain into Avalanche CLI
#
# Imports the existing Numbers Network blockchain so that subsequent
# Avalanche CLI commands can manage it.
#
# Note: This uses 'avalanche blockchain import public' which sets
# ImportedFromAPM=true in the sidecar. The conversion step (03) uses
# 'avalanche blockchain convert' (not 'deploy') because 'deploy'
# rejects imported blockchains.
#
# Usage:
#   ./01-import-blockchain.sh                  # Import testnet (default)
#   NETWORK=mainnet ./01-import-blockchain.sh  # Import mainnet

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

import_blockchain() {
    echo "Step: import_blockchain"
    echo "Importing ${NETWORK_DISPLAY} blockchain into Avalanche CLI..."
    echo ""
    echo "When prompted, provide the following values:"
    echo "  Network:       Fuji Testnet (for testnet) / Mainnet (for mainnet)"
    echo "  RPC endpoint:  ${RPC_URL}"
    echo "  Blockchain ID: ${BLOCKCHAIN_ID}"
    echo "  VM type:       Subnet-EVM"
    echo "  VM version:    v${SUBNET_EVM_VERSION}"
    echo ""

    avalanche blockchain import public
}

verify_import() {
    echo "Step: verify_import"
    echo "Listing imported blockchains..."
    avalanche blockchain list
    echo ""
    echo "Describing ${CHAIN_NAME}..."
    avalanche blockchain describe "${CHAIN_NAME}" || true
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  1. Run ./02-backup-node.sh on each validator node"
    echo "  2. Run ./03-convert-to-l1.sh to execute the conversion"
}

main() {
    show_configs
    echo ""
    import_blockchain
    echo ""
    verify_import
    show_next_action_reminder
}

main

#!/bin/bash
#
# ACP-77 Phase 0: Backup validator node
#
# Backs up staking keys and chain configs before conversion.
# Run this script directly on each validator node.
#
# Usage:
#   ./02-backup-node.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

BACKUP_DIR="${HOME}/acp77-backup-$(date +%Y%m%d-%H%M%S)"

backup_staking() {
    echo "Step: backup_staking"
    if [ -d "${AVALANCHEGO_STAKING_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp -r "${AVALANCHEGO_STAKING_DIR}" "${BACKUP_DIR}/staking"
        echo "Backed up staking keys to ${BACKUP_DIR}/staking/"
    else
        echo "Warning: ${AVALANCHEGO_STAKING_DIR} not found. Skipping."
    fi
}

backup_configs() {
    echo "Step: backup_configs"
    if [ -d "${AVALANCHEGO_CONFIGS_DIR}" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp -r "${AVALANCHEGO_CONFIGS_DIR}" "${BACKUP_DIR}/configs"
        echo "Backed up configs to ${BACKUP_DIR}/configs/"
    else
        echo "Warning: ${AVALANCHEGO_CONFIGS_DIR} not found. Skipping."
    fi
}

backup_run_script() {
    echo "Step: backup_run_script"
    if [ -f "${AVALANCHEGO_BIN_DIR}/run.sh" ]; then
        mkdir -p "${BACKUP_DIR}"
        cp "${AVALANCHEGO_BIN_DIR}/run.sh" "${BACKUP_DIR}/run.sh"
        echo "Backed up run.sh to ${BACKUP_DIR}/run.sh"
    else
        echo "Warning: ${AVALANCHEGO_BIN_DIR}/run.sh not found. Skipping."
    fi
}

show_backup_summary() {
    echo ""
    echo "Backup summary:"
    if [ -d "${BACKUP_DIR}" ]; then
        ls -la "${BACKUP_DIR}/"
        echo ""
        echo "Backup location: ${BACKUP_DIR}"
    else
        echo "No files were backed up."
    fi
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  1. Repeat this script on all validator nodes"
    echo "  2. Run ./03-convert-to-l1.sh from the operator machine"
}

main() {
    show_configs
    echo ""
    echo "Backing up node data to: ${BACKUP_DIR}"
    echo ""
    backup_staking
    backup_configs
    backup_run_script
    show_backup_summary
    show_next_action_reminder
}

main

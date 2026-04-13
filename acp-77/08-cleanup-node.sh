#!/bin/bash
#
# ACP-77 Phase 5: Clean up node disk space
#
# Stops avalanchego, deletes the old database, cleans up old versions,
# and restarts. Run this script directly on the target node.
#
# WARNING: This deletes the node's chain database. The node will need
# to re-sync from scratch, which may take hours.
#
# Prerequisites:
#   - Another validator is active and producing blocks
#   - Node data has been backed up (./02-backup-node.sh)
#
# Usage:
#   ./08-cleanup-node.sh                  # Testnet (default)
#   NETWORK=mainnet ./08-cleanup-node.sh  # Mainnet

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

show_disk_usage() {
    echo "Step: show_disk_usage"
    echo "Current disk usage:"
    df -h /
    echo ""
    if [ -d "${AVALANCHEGO_DB_DIR}" ]; then
        echo "Database size:"
        du -sh "${AVALANCHEGO_DB_DIR}" 2>/dev/null || true
    fi
    echo ""
    echo "Old avalanchego versions:"
    du -sh "${HOME}"/avalanchego-v*/ 2>/dev/null | grep -v "v${AVALANCHEGO_VERSION}/" || echo "  None found"
}

confirm_cleanup() {
    echo ""
    echo "============================================"
    echo "  WARNING: DESTRUCTIVE OPERATION"
    echo "============================================"
    echo ""
    echo "This will:"
    echo "  1. Stop avalanchego"
    echo "  2. Delete the chain database (${AVALANCHEGO_DB_DIR})"
    echo "  3. Remove old avalanchego versions"
    echo "  4. Remove old tar.gz downloads"
    echo "  5. Clean system logs"
    echo "  6. Restart avalanchego"
    echo ""
    echo "The node will need to re-sync from scratch."
    echo ""
    read -p "Type 'CLEANUP' to proceed: " CONFIRM
    if [ "${CONFIRM}" != "CLEANUP" ]; then
        echo "Aborted."
        exit 1
    fi
}

stop_avalanchego() {
    echo ""
    echo "Step: stop_avalanchego"
    PIDS=$(pgrep -f avalanchego 2>/dev/null || true)
    if [ -n "${PIDS}" ]; then
        echo "Stopping avalanchego (PIDs: ${PIDS})..."
        kill ${PIDS}
        sleep 10
        # Verify stopped
        if pgrep -f avalanchego > /dev/null 2>&1; then
            echo "Warning: avalanchego still running. Sending SIGKILL..."
            kill -9 $(pgrep -f avalanchego) 2>/dev/null || true
            sleep 5
        fi
        echo "avalanchego stopped."
    else
        echo "avalanchego is not running."
    fi
}

delete_database() {
    echo ""
    echo "Step: delete_database"
    if [ -d "${AVALANCHEGO_DB_DIR}" ]; then
        DB_SIZE=$(du -sh "${AVALANCHEGO_DB_DIR}" 2>/dev/null | cut -f1)
        echo "Deleting database (${DB_SIZE})..."
        rm -rf "${AVALANCHEGO_DB_DIR}"
        echo "Database deleted."
    else
        echo "No database directory found at ${AVALANCHEGO_DB_DIR}"
    fi
}

clean_old_versions() {
    echo ""
    echo "Step: clean_old_versions"
    echo "Removing old avalanchego versions (keeping v${AVALANCHEGO_VERSION})..."
    CLEANED=0
    for d in "${HOME}"/avalanchego-v*/; do
        [ ! -d "$d" ] && continue
        DIR_NAME=$(basename "$d")
        if [ "${DIR_NAME}" != "avalanchego-v${AVALANCHEGO_VERSION}" ]; then
            echo "  Removing ${DIR_NAME}/"
            rm -rf "$d"
            CLEANED=$((CLEANED + 1))
        fi
    done
    echo "  Removed ${CLEANED} old version(s)."
}

clean_downloads() {
    echo ""
    echo "Step: clean_downloads"
    echo "Removing old download archives..."

    COUNT=0
    for f in "${HOME}"/avalanchego-linux-amd64-*.tar.gz*; do
        [ ! -f "$f" ] && continue
        rm -f "$f"
        COUNT=$((COUNT + 1))
    done
    for f in "${HOME}"/subnet-evm_*.tar.gz*; do
        [ ! -f "$f" ] && continue
        rm -f "$f"
        COUNT=$((COUNT + 1))
    done
    echo "  Removed ${COUNT} archive file(s)."
}

clean_logs() {
    echo ""
    echo "Step: clean_logs"

    # Clean avalanchego logs (keep current)
    if [ -d "${AVALANCHEGO_LOGS_DIR}" ]; then
        LOG_COUNT=$(find "${AVALANCHEGO_LOGS_DIR}" -name "*.log.*" 2>/dev/null | wc -l)
        if [ "${LOG_COUNT}" -gt 0 ]; then
            echo "  Removing ${LOG_COUNT} rotated avalanchego log file(s)..."
            find "${AVALANCHEGO_LOGS_DIR}" -name "*.log.*" -delete
        fi
    fi

    # Clean system journal
    if command -v journalctl &> /dev/null; then
        echo "  Vacuuming system journal to 500M..."
        sudo journalctl --vacuum-size=500M 2>/dev/null || echo "  (skipped - no sudo access)"
    fi
}

restart_avalanchego() {
    echo ""
    echo "Step: restart_avalanchego"
    if [ -f "${AVALANCHEGO_BIN_DIR}/run.sh" ]; then
        echo "Starting avalanchego from ${AVALANCHEGO_BIN_DIR}/run.sh..."
        cd "${AVALANCHEGO_BIN_DIR}"
        nohup ./run.sh > "${HOME}/avalanchego-restart.log" 2>&1 &
        sleep 3
        if pgrep -f avalanchego > /dev/null 2>&1; then
            echo "avalanchego started (PID: $(pgrep -f avalanchego | head -1))"
        else
            echo "Warning: avalanchego may not have started. Check ${HOME}/avalanchego-restart.log"
        fi
    else
        echo "Warning: ${AVALANCHEGO_BIN_DIR}/run.sh not found."
        echo "Please start avalanchego manually."
    fi
}

show_result() {
    echo ""
    echo "============================================"
    echo "  Cleanup Complete"
    echo "============================================"
    echo ""
    echo "Disk usage after cleanup:"
    df -h /
    echo ""
    echo "The node is now re-syncing. Monitor progress with:"
    echo "  watch -n 30 'curl -s -X POST --data \"{\\\"jsonrpc\\\":\\\"2.0\\\",\\\"id\\\":1,\\\"method\\\":\\\"info.isBootstrapped\\\",\\\"params\\\":{\\\"chain\\\":\\\"${BLOCKCHAIN_ID}\\\"}}\" -H \"Content-Type: application/json\" http://127.0.0.1:9650/ext/info'"
}

main() {
    show_configs
    echo ""
    show_disk_usage
    confirm_cleanup
    stop_avalanchego
    delete_database
    clean_old_versions
    clean_downloads
    clean_logs
    restart_avalanchego
    show_result
}

main

#!/bin/bash

AVALANCHEGO_PREVIOUS_VERSION="1.10.7"
AVALANCHEGO_VERSION="1.10.11"
SUBNET_EVM_VERSION="0.5.6"
# Numbers Mainnet
VM_ID="qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx"
SUBNET_ID="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"

HEALTH_ENDPOINT="127.0.0.1:9650/ext/health"
HEALTH_TIMEOUT=60
BACKUP_DIR="${HOME}/validator-backups"
DRY_RUN=false
ROLLBACK=false

# Parse flags
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true ;;
        --rollback) ROLLBACK=true ;;
    esac
done

preflight_checks() {
    echo "Step: preflight_checks"
    local required_tools="wget tar sha256sum tree jq curl"
    for tool in $required_tools; do
        if ! command -v "$tool" &>/dev/null; then
            echo "ERROR: Required tool '$tool' is not installed." >&2
            exit 1
        fi
    done
    local required_kb=2097152  # 2 GB
    local available_kb
    available_kb=$(df -k "$HOME" | awk 'NR==2{print $4}')
    if [ "$available_kb" -lt "$required_kb" ]; then
        echo "ERROR: Insufficient disk space. Need at least 2 GB free in $HOME." >&2
        exit 1
    fi
    echo "Pre-flight checks passed."
}

create_backup() {
    echo "Step: create_backup"
    mkdir -p "${BACKUP_DIR}"
    local backup_file="${BACKUP_DIR}/validator-backup-pre-${AVALANCHEGO_VERSION}-$(date +%Y%m%d%H%M%S).tar.gz"
    local backup_sources=""
    [ -d "${HOME}/avalanchego-v${AVALANCHEGO_PREVIOUS_VERSION}" ] && backup_sources="${backup_sources} avalanchego-v${AVALANCHEGO_PREVIOUS_VERSION}"
    [ -f "${HOME}/.avalanchego/plugins/${VM_ID}" ] && backup_sources="${backup_sources} .avalanchego/plugins/${VM_ID}"
    if [ -n "$backup_sources" ]; then
        tar czf "${backup_file}" -C "${HOME}" $backup_sources
        tar -tzf "${backup_file}" >/dev/null 2>&1 || { echo "ERROR: Backup archive is corrupt." >&2; exit 1; }
        echo "Backup created and verified: ${backup_file}"
    else
        echo "No existing validator files found to back up; skipping backup."
    fi
}

rollback() {
    echo "Step: rollback"
    local latest_backup
    latest_backup=$(ls -t "${BACKUP_DIR}"/validator-backup-pre-*.tar.gz 2>/dev/null | head -1)
    if [ -z "$latest_backup" ]; then
        echo "ERROR: No backup found to roll back to." >&2
        exit 1
    fi
    echo "Restoring from backup: ${latest_backup}"
    tar -tzf "${latest_backup}" >/dev/null 2>&1 || { echo "ERROR: Backup archive is corrupt." >&2; exit 1; }
    tar xzf "${latest_backup}" -C "${HOME}"
    echo "Rollback complete. Please restart the validator manually."
}

download_avalanchego() {
    echo "Step: download_avalanchego"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would download avalanchego v${AVALANCHEGO_VERSION}"
        return
    fi
    wget https://github.com/ava-labs/avalanchego/releases/download/v${AVALANCHEGO_VERSION}/avalanchego-linux-amd64-v${AVALANCHEGO_VERSION}.tar.gz
    tar xzf avalanchego-linux-amd64-v${AVALANCHEGO_VERSION}.tar.gz
    cp avalanchego-v${AVALANCHEGO_PREVIOUS_VERSION}/run.sh avalanchego-v${AVALANCHEGO_VERSION}/
}

download_sunbet_evm() {
    echo "Step: download_sunbet_evm"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would download subnet-evm v${SUBNET_EVM_VERSION}"
        return
    fi
    mkdir subnet-evm-${SUBNET_EVM_VERSION}
    wget https://github.com/ava-labs/subnet-evm/releases/download/v${SUBNET_EVM_VERSION}/subnet-evm_${SUBNET_EVM_VERSION}_linux_amd64.tar.gz
    tar xzf subnet-evm_${SUBNET_EVM_VERSION}_linux_amd64.tar.gz -C subnet-evm-${SUBNET_EVM_VERSION}
}

update_subnet_evm() {
    echo "Step: update_subnet_evm"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] Would update subnet-evm plugin to v${SUBNET_EVM_VERSION}"
        return
    fi
    cp subnet-evm-${SUBNET_EVM_VERSION}/subnet-evm ~/.avalanchego/plugins/${VM_ID}
    sha256sum subnet-evm-${SUBNET_EVM_VERSION}/subnet-evm ~/.avalanchego/plugins/${VM_ID}
}

show_validator_files() {
    echo "Step: show_validator_files"
    tree avalanchego-v${AVALANCHEGO_VERSION}
    tree ~/.avalanchego/plugins/
}

show_configs() {
    echo "Step: show_configs"
    echo "AVALANCHEGO_PREVIOUS_VERSION: ${AVALANCHEGO_PREVIOUS_VERSION}"
    echo "AVALANCHEGO_VERSION: ${AVALANCHEGO_VERSION}"
    echo "SUBNET_EVM_VERSION: ${SUBNET_EVM_VERSION}"
    echo "VM_ID (Mainnet): ${VM_ID}"
    echo "SUBNET_ID (Mainnet): ${SUBNET_ID}"
}

health_check() {
    echo "Step: health_check"
    echo "Waiting up to ${HEALTH_TIMEOUT}s for validator health endpoint..."
    local elapsed=0
    local interval=5
    while [ "$elapsed" -lt "$HEALTH_TIMEOUT" ]; do
        local response
        response=$(curl -sf -X POST --data '{"jsonrpc":"2.0","id":1,"method":"health.health"}' \
            -H 'content-type:application/json;' "${HEALTH_ENDPOINT}" 2>/dev/null)
        if echo "$response" | jq -e '.result.healthy == true' >/dev/null 2>&1; then
            echo "Validator is healthy."
            return 0
        fi
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
    echo "ERROR: Validator did not become healthy within ${HEALTH_TIMEOUT}s. Initiating rollback..." >&2
    rollback
    exit 1
}

show_next_action_reminder() {
    echo "Step: show_next_action_reminder"
    echo "Now, you are ready to start the validator"
    echo "$ cd ~/avalanchego-v${AVALANCHEGO_VERSION}"
    echo "$ ./run.sh"
    echo ""
    echo "Check validators"
    echo "$ cd ~/avalanchego-api-scripts/api"
    echo "$ ./platform.getCurrentValidators.sh ${SUBNET_ID} | jq ."
    echo "$ ./info.peers.sh  | jq ."
}

main() {
    if [ "$ROLLBACK" = true ]; then
        rollback
        exit 0
    fi
    show_configs
    preflight_checks
    create_backup
    download_avalanchego
    download_sunbet_evm
    update_subnet_evm
    if [ "$DRY_RUN" = false ]; then
        show_validator_files
        show_next_action_reminder
        echo "Start the validator, then run '$0' again to trigger a health check,"
        echo "or call the health_check function directly in a wrapper script."
    fi
}

main "$@"


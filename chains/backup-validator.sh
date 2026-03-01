#!/bin/sh

# Backup Avalanche validator

TARGET_DIR=".avalanchego/staking/"
BACKUP_FILE_NAME="$(hostname).tar.gz"

cd ~
tar czvf ${BACKUP_FILE_NAME} ${TARGET_DIR}
echo "Backup ${TARGET_DIR} to ${PWD}/${BACKUP_FILE_NAME}"

echo "Verifying backup archive integrity..."
tar -tzf ${BACKUP_FILE_NAME} >/dev/null 2>&1 || { echo "ERROR: Backup archive is corrupt: ${PWD}/${BACKUP_FILE_NAME}" >&2; exit 1; }
echo "Backup verification passed: ${PWD}/${BACKUP_FILE_NAME}"


#!/bin/sh

# Backup Avalanche validator

TARGET_DIR=".avalanchego/staking/"
BACKUP_FILE_NAME="$(hostname).tar.gz"

cd ~
tar czvf ${BACKUP_FILE_NAME} ${TARGET_DIR}
echo "Backup ${TARGET_DIR} to ${PWD}/${BACKUP_FILE_NAME}"


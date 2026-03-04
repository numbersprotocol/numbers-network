#!/bin/bash
set -euo pipefail

# Backup Avalanche validator

TARGET_DIR="$HOME/.avalanchego/staking/"
BACKUP_FILE_NAME="$HOME/$(hostname)-staking-$(date +%Y%m%d-%H%M%S).tar.gz"

umask 077
tar czf "$BACKUP_FILE_NAME" -C "$HOME" ".avalanchego/staking/"
chmod 600 "$BACKUP_FILE_NAME"
echo "Backup created: $BACKUP_FILE_NAME (permissions: 600)"
# Consider encrypting with: gpg --symmetric --cipher-algo AES256 "$BACKUP_FILE_NAME"


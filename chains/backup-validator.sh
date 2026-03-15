#!/bin/sh

# Backup Avalanche validator staking keys with encryption and integrity verification.
#
# Prerequisites:
#   - gpg must be installed
#   - A passphrase file must exist at the path specified by PASSPHRASE_FILE
#
# Usage:
#   PASSPHRASE_FILE=/path/to/passphrase ./backup-validator.sh
#
# Optional remote upload (uncomment and configure the upload section below):
#   Supports any rclone-compatible remote (S3, GCS, Azure, SFTP, etc.)
#   See https://rclone.org/ for setup instructions.

TARGET_DIR=".avalanchego/staking/"
BACKUP_FILE_NAME="$(hostname).tar.gz.gpg"
CHECKSUM_FILE="${BACKUP_FILE_NAME}.sha256"

# Path to a file containing the GPG passphrase (chmod 600 recommended)
PASSPHRASE_FILE="${PASSPHRASE_FILE:-/etc/avalanche/backup-passphrase}"

if [ ! -f "${PASSPHRASE_FILE}" ]; then
    echo "ERROR: Passphrase file not found: ${PASSPHRASE_FILE}" >&2
    echo "Set the PASSPHRASE_FILE environment variable or create the file." >&2
    exit 1
fi

cd ~

# Create encrypted backup using AES-256 symmetric encryption
tar czf - "${TARGET_DIR}" | \
    gpg --symmetric \
        --cipher-algo AES256 \
        --batch \
        --passphrase-file "${PASSPHRASE_FILE}" \
        --output "${BACKUP_FILE_NAME}"

if [ $? -ne 0 ]; then
    echo "ERROR: Backup encryption failed." >&2
    exit 1
fi

# Generate SHA-256 checksum for integrity verification
sha256sum "${BACKUP_FILE_NAME}" > "${CHECKSUM_FILE}"

echo "Backup created:  ${PWD}/${BACKUP_FILE_NAME}"
echo "Checksum file:   ${PWD}/${CHECKSUM_FILE}"

# Verify the checksum immediately after creation
sha256sum --check "${CHECKSUM_FILE}"
if [ $? -ne 0 ]; then
    echo "ERROR: Checksum verification failed." >&2
    exit 1
fi

echo "Integrity check passed."

# --- Optional: Upload to remote/offsite storage ---
# Uncomment and configure the section below to enable remote backup upload.
# Requires rclone to be installed and configured (https://rclone.org/).
#
# REMOTE_DEST="s3:my-bucket/avalanche-backups"
# rclone copy "${BACKUP_FILE_NAME}" "${REMOTE_DEST}/"
# rclone copy "${CHECKSUM_FILE}" "${REMOTE_DEST}/"
# echo "Uploaded backup to ${REMOTE_DEST}"

# --- Optional: Retention policy ---
# Remove local encrypted backups older than 30 days to manage disk usage.
# Adjust the -mtime value to match your retention requirements.
#
# find ~ -name "*.tar.gz.gpg" -mtime +30 -delete
# find ~ -name "*.tar.gz.gpg.sha256" -mtime +30 -delete
# echo "Old backups pruned."


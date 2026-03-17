#!/usr/bin/env bash
# disk-check.sh — Cron-deployable disk usage monitor for GCE instances.
#
# Checks every mounted filesystem and fires alerts when usage crosses
# configurable WARNING (default 80%) or CRITICAL (default 90%) thresholds.
#
# Alert channels supported:
#   • Email  — requires a local MTA (sendmail/postfix) or mailx
#   • Slack  — requires SLACK_WEBHOOK_URL env variable (or set below)
#
# Recommended cron entry (runs every 15 minutes):
#   */15 * * * * /opt/numbers-network/monitoring/disk-check.sh >> /var/log/disk-check.log 2>&1
#
# Environment variables (can also be hard-coded in the CONFIG section):
#   DISK_WARNING_PCT   — percentage threshold for WARNING (default 80)
#   DISK_CRITICAL_PCT  — percentage threshold for CRITICAL (default 90)
#   ALERT_EMAIL        — email address for alert delivery
#   SLACK_WEBHOOK_URL  — Slack incoming-webhook URL
#   INSTANCE_NAME      — human-readable instance name (defaults to hostname)

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIG — override via environment variables or edit here
# ---------------------------------------------------------------------------
WARNING_PCT="${DISK_WARNING_PCT:-80}"
CRITICAL_PCT="${DISK_CRITICAL_PCT:-90}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
INSTANCE="${INSTANCE_NAME:-$(hostname)}"
TIMESTAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

# Filesystems to skip (space-separated list of mount-point prefixes)
SKIP_MOUNTS="${DISK_SKIP_MOUNTS:-/dev /proc /sys /run /snap}"

# ---------------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------------

log() {
    echo "[${TIMESTAMP}] $*"
}

# Send an email alert. Requires mailx or sendmail.
send_email() {
    local subject="$1"
    local body="$2"
    if [[ -z "${ALERT_EMAIL}" ]]; then
        return
    fi
    if command -v mailx &>/dev/null; then
        echo "${body}" | mailx -s "${subject}" "${ALERT_EMAIL}"
    elif command -v sendmail &>/dev/null; then
        { echo "Subject: ${subject}"; echo ""; echo "${body}"; } | sendmail "${ALERT_EMAIL}"
    else
        log "WARN: No mail client found — email alert skipped."
    fi
}

# Post a message to Slack via incoming webhook.
send_slack() {
    local message="$1"
    if [[ -z "${SLACK_WEBHOOK_URL}" ]]; then
        return
    fi
    if ! command -v curl &>/dev/null; then
        log "WARN: curl not found — Slack alert skipped."
        return
    fi
    local payload
    payload=$(printf '{"text": "%s"}' "${message}")
    curl -s -X POST -H 'Content-type: application/json' \
        --data "${payload}" \
        "${SLACK_WEBHOOK_URL}" >/dev/null
}

# Determine if a mount point should be skipped.
should_skip() {
    local mount="$1"
    for prefix in ${SKIP_MOUNTS}; do
        if [[ "${mount}" == "${prefix}" || "${mount}" == "${prefix}"/* ]]; then
            return 0
        fi
    done
    return 1
}

# ---------------------------------------------------------------------------
# MAIN DISK CHECK
# ---------------------------------------------------------------------------

ALERT_TRIGGERED=0

# Parse df output: filesystem, size, used, available, use%, mountpoint
while IFS= read -r line; do
    # Skip header line
    [[ "${line}" =~ ^Filesystem ]] && continue

    # Extract columns (df -P produces POSIX format: guaranteed single-line per FS)
    read -r filesystem size used avail pct mount <<< "${line}"

    # Remove trailing '%' from pct
    pct_num="${pct//%/}"

    # Skip non-numeric (e.g. headers that slipped through)
    [[ "${pct_num}" =~ ^[0-9]+$ ]] || continue

    # Skip excluded mount points
    should_skip "${mount}" && continue

    if (( pct_num >= CRITICAL_PCT )); then
        level="CRITICAL"
        ALERT_TRIGGERED=1
    elif (( pct_num >= WARNING_PCT )); then
        level="WARNING"
        ALERT_TRIGGERED=1
    else
        level="OK"
    fi

    log "[${level}] ${mount} — ${pct_num}% used (${used}/${size}) on ${filesystem}"

    if [[ "${level}" != "OK" ]]; then
        subject="[Disk ${level}] ${INSTANCE} — ${mount} at ${pct_num}%"
        body=$(printf "Instance : %s\nTimestamp: %s\nMount    : %s\nUsage    : %s%% (%s used of %s, %s free)\nFilesys  : %s\n\nThresholds: WARNING>=%s%% | CRITICAL>=%s%%" \
            "${INSTANCE}" "${TIMESTAMP}" "${mount}" "${pct_num}" \
            "${used}" "${size}" "${avail}" "${filesystem}" \
            "${WARNING_PCT}" "${CRITICAL_PCT}")
        slack_msg="[Disk ${level}] *${INSTANCE}* — \`${mount}\` is at *${pct_num}%* (${used}/${size}). Investigate immediately."

        send_email "${subject}" "${body}"
        send_slack "${slack_msg}"
    fi
done < <(df -P -h --output=source,size,used,avail,pcent,target 2>/dev/null || df -P 2>/dev/null)

if (( ALERT_TRIGGERED == 0 )); then
    log "[OK] All filesystems below warning threshold (${WARNING_PCT}%)."
fi

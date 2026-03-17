#!/usr/bin/env bash
# setup-gcp-disk-alerts.sh — Provision GCP Cloud Monitoring alerting policies
# for disk utilisation across all Numbers Network GCE instances.
#
# This script uses the gcloud CLI to create:
#   1. (Optional) A Slack or email notification channel
#   2. A WARNING alerting policy  — fires when disk used > 80%
#   3. A CRITICAL alerting policy — fires when disk used > 90%
#
# Pre-requisites:
#   • gcloud CLI installed and authenticated (`gcloud auth login`)
#   • Target GCP project set (`gcloud config set project PROJECT_ID`)
#   • roles/monitoring.alertPolicyEditor (or Owner) on the project
#
# Usage:
#   export GCP_PROJECT=your-gcp-project-id
#   export ALERT_EMAIL=ops@example.com          # optional
#   export SLACK_CHANNEL_NAME=numbers-disk-alerts  # optional
#   export SLACK_AUTH_TOKEN=xoxb-...            # optional — required for Slack
#   bash setup-gcp-disk-alerts.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
GCP_PROJECT="${GCP_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
SLACK_CHANNEL_NAME="${SLACK_CHANNEL_NAME:-}"
SLACK_AUTH_TOKEN="${SLACK_AUTH_TOKEN:-}"

POLICY_PREFIX="numbers-network-disk"

# Disk utilisation thresholds (0–100 as a ratio stored in GCP: 0.80 = 80%)
WARNING_RATIO="0.80"
CRITICAL_RATIO="0.90"

# Alert duration: how long the threshold must be exceeded before firing (seconds)
DURATION_WARNING="300s"   # 5 minutes
DURATION_CRITICAL="60s"   # 1 minute

# GCP Ops Agent disk utilisation metric used by the alerting policies
DISK_METRIC="agent.googleapis.com/disk/percent_used"

if [[ -z "${GCP_PROJECT}" ]]; then
    echo "ERROR: GCP_PROJECT is not set. Run: export GCP_PROJECT=<your-project-id>"
    exit 1
fi

echo "==> Configuring GCP Monitoring alerts for project: ${GCP_PROJECT}"

# ---------------------------------------------------------------------------
# 1. CREATE NOTIFICATION CHANNELS
# ---------------------------------------------------------------------------
NOTIFICATION_CHANNELS=""

# --- Email channel ---
if [[ -n "${ALERT_EMAIL}" ]]; then
    echo "==> Creating email notification channel for: ${ALERT_EMAIL}"
    EMAIL_CHANNEL=$(gcloud beta monitoring channels create \
        --display-name="Numbers Disk Alerts (Email)" \
        --type=email \
        --channel-labels="email_address=${ALERT_EMAIL}" \
        --project="${GCP_PROJECT}" \
        --format="value(name)" 2>/dev/null) || true
    if [[ -n "${EMAIL_CHANNEL}" ]]; then
        echo "    Channel created: ${EMAIL_CHANNEL}"
        NOTIFICATION_CHANNELS="${EMAIL_CHANNEL}"
    fi
fi

# --- Slack channel ---
if [[ -n "${SLACK_CHANNEL_NAME}" && -n "${SLACK_AUTH_TOKEN}" ]]; then
    echo "==> Creating Slack notification channel: #${SLACK_CHANNEL_NAME}"
    SLACK_CHANNEL=$(gcloud beta monitoring channels create \
        --display-name="Numbers Disk Alerts (Slack #${SLACK_CHANNEL_NAME})" \
        --type=slack \
        --channel-labels="channel_name=${SLACK_CHANNEL_NAME}" \
        --sensitive-labels="auth_token=${SLACK_AUTH_TOKEN}" \
        --project="${GCP_PROJECT}" \
        --format="value(name)" 2>/dev/null) || true
    if [[ -n "${SLACK_CHANNEL}" ]]; then
        echo "    Channel created: ${SLACK_CHANNEL}"
        NOTIFICATION_CHANNELS="${NOTIFICATION_CHANNELS:+${NOTIFICATION_CHANNELS},}${SLACK_CHANNEL}"
    fi
fi

# ---------------------------------------------------------------------------
# 2. HELPER: create an alerting policy via inline JSON
# ---------------------------------------------------------------------------
create_policy() {
    local display_name="$1"
    local threshold="$2"
    local duration="$3"
    local severity="$4"    # WARNING | CRITICAL

    # Build notification-channel array
    local nc_array="[]"
    if [[ -n "${NOTIFICATION_CHANNELS}" ]]; then
        # Convert comma-separated list to JSON array
        nc_array=$(echo "${NOTIFICATION_CHANNELS}" | tr ',' '\n' \
            | awk '{printf "\"%s\",", $0}' | sed 's/,$//' | awk '{print "[" $0 "]"}')
    fi

    # The GCP metric for disk utilisation on GCE instances
    local metric="${DISK_METRIC}"

    cat > /tmp/gcp_alert_policy.json <<EOF
{
  "displayName": "${display_name}",
  "documentation": {
    "content": "Disk utilisation on a Numbers Network GCE instance has exceeded the ${severity} threshold (${threshold} ratio). Refer to the runbook: https://github.com/numbersprotocol/numbers-network/blob/main/docs/runbooks/disk-management.md",
    "mimeType": "text/markdown"
  },
  "conditions": [
    {
      "displayName": "Disk utilisation ${severity}: > ${threshold}",
      "conditionThreshold": {
        "filter": "resource.type=\"gce_instance\" AND metric.type=\"${metric}\" AND metric.labels.state=\"used\"",
        "aggregations": [
          {
            "alignmentPeriod": "60s",
            "crossSeriesReducer": "REDUCE_MEAN",
            "perSeriesAligner": "ALIGN_MEAN",
            "groupByFields": ["resource.labels.instance_id", "resource.labels.zone"]
          }
        ],
        "comparison": "COMPARISON_GT",
        "thresholdValue": ${threshold},
        "duration": "${duration}",
        "trigger": {
          "count": 1
        }
      }
    }
  ],
  "alertStrategy": {
    "notificationRateLimit": {
      "period": "3600s"
    },
    "autoClose": "604800s"
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": ${nc_array},
  "severity": "${severity}"
}
EOF

    gcloud alpha monitoring policies create \
        --policy-from-file=/tmp/gcp_alert_policy.json \
        --project="${GCP_PROJECT}" \
        --format="value(name)"
}

# ---------------------------------------------------------------------------
# 3. CREATE WARNING POLICY (>80% for 5 minutes)
# ---------------------------------------------------------------------------
echo "==> Creating WARNING alerting policy (>${WARNING_RATIO} for ${DURATION_WARNING})"
WARNING_POLICY=$(create_policy \
    "${POLICY_PREFIX}-warning" \
    "${WARNING_RATIO}" \
    "${DURATION_WARNING}" \
    "WARNING") || true
echo "    Policy created: ${WARNING_POLICY}"

# ---------------------------------------------------------------------------
# 4. CREATE CRITICAL POLICY (>90% for 1 minute)
# ---------------------------------------------------------------------------
echo "==> Creating CRITICAL alerting policy (>${CRITICAL_RATIO} for ${DURATION_CRITICAL})"
CRITICAL_POLICY=$(create_policy \
    "${POLICY_PREFIX}-critical" \
    "${CRITICAL_RATIO}" \
    "${DURATION_CRITICAL}" \
    "CRITICAL") || true
echo "    Policy created: ${CRITICAL_POLICY}"

# ---------------------------------------------------------------------------
# 5. SUMMARY
# ---------------------------------------------------------------------------
echo ""
echo "==> Done. Summary:"
echo "    Project           : ${GCP_PROJECT}"
echo "    Notification chans: ${NOTIFICATION_CHANNELS:-<none>}"
echo "    Warning policy    : ${WARNING_POLICY:-<not created>}"
echo "    Critical policy   : ${CRITICAL_POLICY:-<not created>}"
echo ""
echo "Next steps:"
echo "  1. Install the Ops Agent on each GCE instance so that the"
echo "     '${DISK_METRIC}' metric is reported:"
echo "     https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/installation"
echo "  2. Verify policies in the GCP Console:"
echo "     https://console.cloud.google.com/monitoring/alerting?project=${GCP_PROJECT}"
echo "  3. Deploy monitoring/disk-check.sh to each instance as a cron fallback."

# Disk Management Runbook

**Status**: Active  
**Last Updated**: 2026-03-17  
**Applies to**: All Numbers Network GCE instances (mainnet validators, testnet validators, explorers)

---

## Table of Contents

- [Background](#background)
- [Alert Thresholds](#alert-thresholds)
- [Instance Inventory](#instance-inventory)
- [Immediate Triage](#immediate-triage)
- [Remediation: Expand a GCE Persistent Disk (Online)](#remediation-expand-a-gce-persistent-disk-online)
- [Remediation: Avalanchego Chain Data Pruning](#remediation-avalanchego-chain-data-pruning)
- [Remediation: Blockscout / Explorer Database Cleanup](#remediation-blockscout--explorer-database-cleanup)
- [Automated Monitoring Setup](#automated-monitoring-setup)
- [Incident History](#incident-history)

---

## Background

GCE instances running Avalanche validators accumulate blockchain data continuously.
Without monitoring, disks can silently fill to 100%, triggering an automatic OS-level
shutdown of the validator node. This causes:

- Chain downtime for Numbers Network validators
- Transaction mempool backlog
- Potential double-sign risk if the node rejoins without catching up

The 2026-03-15 incident on `numbers-mainnet-validator-1` (auto-shutdown at 97% disk)
and the 2026-03-17 situation on `numbers-testnet-validator-3` (96% disk) prompted
implementation of this runbook.

---

## Alert Thresholds

| Level    | Threshold | Action Required                            |
|----------|-----------|--------------------------------------------|
| OK       | < 80%     | No action                                  |
| WARNING  | ≥ 80%     | Schedule cleanup or expansion within 48 h  |
| CRITICAL | ≥ 90%     | Immediate action — expand or prune today   |
| DANGER   | ≥ 97%     | Emergency — node may auto-shutdown         |

---

## Instance Inventory

| Instance                    | Typical Disk | Growth Rate      | Notes                    |
|-----------------------------|-------------|------------------|--------------------------|
| numbers-mainnet-validator-1 | 3.4 T       | ~20 GB/day       | Primary mainnet validator |
| numbers-mainnet-validator-a1| 1.9 T       | ~15 GB/day       |                          |
| numbers-mainnet-validator-a2| 2.0 T       | ~15 GB/day       |                          |
| numbers-testnet-validator-3 | 497 G       | ~5 GB/day        | Testnet — smaller disk   |
| testnet-explorer            | 29 G        | ~500 MB/day      | Blockscout explorer      |
| mainnet-explorer            | 47 G        | ~1 GB/day        | Blockscout explorer      |

---

## Immediate Triage

Run these commands on the affected instance to understand disk consumption:

```bash
# Overall disk usage
df -h

# Top disk consumers in the avalanche data directory
sudo du -sh /home/ubuntu/.avalanchego/* 2>/dev/null | sort -rh | head -20

# Top disk consumers in blockchain chain data
sudo du -sh /home/ubuntu/.avalanchego/db/*/chainData 2>/dev/null | sort -rh | head -10

# Log file sizes
sudo du -sh /var/log/* 2>/dev/null | sort -rh | head -10

# Docker volumes (if applicable)
docker system df 2>/dev/null || true
```

---

## Remediation: Expand a GCE Persistent Disk (Online)

GCE supports **online disk expansion** — the instance stays running throughout.

### Step 1 — Resize the persistent disk in GCP

```bash
# Using gcloud CLI (replace variables as appropriate)
INSTANCE_NAME="numbers-testnet-validator-3"
ZONE="us-central1-a"           # adjust to the actual zone
DISK_NAME="${INSTANCE_NAME}"   # disk usually shares the instance name
NEW_SIZE_GB=600                # desired new size in GiB

gcloud compute disks resize "${DISK_NAME}" \
    --size="${NEW_SIZE_GB}GB" \
    --zone="${ZONE}"
```

You can also do this in the [GCP Console](https://console.cloud.google.com/compute/disks):
**Compute Engine → Disks → select disk → Edit → increase size**.

> ⚠️ GCE disks can only be **increased** in size, never decreased.

### Step 2 — Grow the partition on the instance

SSH into the instance and run:

```bash
# Confirm the disk device (usually /dev/sda or /dev/nvme0n1)
lsblk

# Grow the partition (number 1 in most GCE instances)
sudo growpart /dev/sda 1
# or for NVMe:
sudo growpart /dev/nvme0n1 1
```

### Step 3 — Resize the filesystem (no unmounting required)

```bash
# For ext4 filesystems (most GCE boot/data disks)
sudo resize2fs /dev/sda1
# or for NVMe:
sudo resize2fs /dev/nvme0n1p1

# Verify the new size is reflected
df -h /
```

For **XFS** filesystems:

```bash
sudo xfs_growfs /
```

### Verification

```bash
df -h
# The mount point should now show the expanded capacity.
```

---

## Remediation: Avalanchego Chain Data Pruning

Avalanchego accumulates historical state data under `~/.avalanchego/db/`.
The two main strategies are **state pruning** (EVM) and **network pruning** (P/X/C chains).

### Check current data sizes

```bash
sudo du -sh ~/.avalanchego/db/*/
sudo du -sh ~/.avalanchego/db/*/*/ 2>/dev/null | sort -rh | head -20
```

### Option A — Enable state pruning in the EVM chain config

> Applies to **validators** only — do **not** enable on archive nodes.

Edit the chain config (see `avalanchego/configs/chains/<blockchain-id>/config-validator.json`):

```json
{
    "pruning-enabled": true,
    "state-sync-enabled": false
}
```

Restart avalanchego:

```bash
sudo systemctl restart avalanchego
```

On first restart with pruning enabled, the node will begin compacting its LevelDB state.
This takes several hours and temporarily increases CPU/disk I/O.

### Option B — State-sync re-sync (fastest, but requires downtime)

State-sync downloads only the latest state rather than replaying all historical blocks.
This is the fastest way to reclaim large amounts of disk space.

```bash
# 1. Stop the node
sudo systemctl stop avalanchego

# 2. Remove the chain database (preserves staking keys)
BLOCKCHAIN_ID="2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE"  # mainnet
# BLOCKCHAIN_ID="2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ"  # testnet
sudo rm -rf ~/.avalanchego/db/*/chainData   # removes only chain data

# 3. Enable state-sync in the chain config
#    Set "state-sync-enabled": true in the relevant config.json

# 4. Restart — the node will state-sync from peers
sudo systemctl start avalanchego
sudo journalctl -fu avalanchego
```

> ⚠️ The node will not be able to serve historical RPC requests until it fully catches up.
> Do **not** use this on an archive node.

### Option C — Remove old log files

```bash
# Rotate and compress logs immediately
sudo logrotate -f /etc/logrotate.d/avalanchego 2>/dev/null || true

# Remove logs older than 7 days
sudo find ~/.avalanchego/logs/ -name "*.log" -mtime +7 -delete
sudo find /var/log/ -name "*.gz" -mtime +30 -delete
```

### Option D — Remove old snapshots

```bash
# List and remove snapshots (keep at least one recent snapshot)
ls -lh ~/.avalanchego/db/*/snapshots/ 2>/dev/null
# Identify and delete old snapshots after confirming the node is healthy
sudo rm -rf ~/.avalanchego/db/*/snapshots/<old-snapshot-name>
```

---

## Remediation: Blockscout / Explorer Database Cleanup

Explorer instances (`testnet-explorer`, `mainnet-explorer`) run Blockscout backed by
PostgreSQL. The database is the primary disk consumer.

### Check database size

```bash
# Connect to PostgreSQL (adjust credentials)
sudo -u postgres psql -c "\l+"
sudo -u postgres psql -d blockscout -c "
  SELECT pg_size_pretty(pg_database_size('blockscout')) AS db_size;
"

# Largest tables
sudo -u postgres psql -d blockscout -c "
  SELECT relname AS table,
         pg_size_pretty(pg_total_relation_size(relid)) AS total_size
  FROM pg_catalog.pg_statio_user_tables
  ORDER BY pg_total_relation_size(relid) DESC
  LIMIT 20;
"
```

### Option A — VACUUM and ANALYZE

Running VACUUM reclaims space from deleted/updated rows without downtime:

```bash
sudo -u postgres psql -d blockscout -c "VACUUM ANALYZE;"
# For a more aggressive reclaim (brief table locks):
sudo -u postgres psql -d blockscout -c "VACUUM FULL ANALYZE;"
```

### Option B — Prune old transaction data (if supported by Blockscout version)

Some Blockscout versions support data pruning. Check:

```bash
cat /opt/blockscout/.env | grep -i prune
# If BLOCK_TRANSFORMER=base and version supports it, add:
# INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER=true
# to reduce ongoing growth
```

### Option C — Expand the explorer disk

Follow the same [GCE disk expansion steps](#remediation-expand-a-gce-persistent-disk-online)
above. Explorer disks are typically smaller so expansion is inexpensive.

### Option D — Docker volume cleanup (if using Docker deployment)

```bash
# Remove dangling images and stopped containers
docker system prune -f

# Show volume usage
docker system df -v
```

---

## Automated Monitoring Setup

### Option 1 — Cron-based instance-level script (fallback)

Deploy `monitoring/disk-check.sh` from this repository to each instance:

```bash
# On each GCE instance:
sudo mkdir -p /opt/numbers-network/monitoring
sudo cp /path/to/repo/monitoring/disk-check.sh /opt/numbers-network/monitoring/
sudo chmod +x /opt/numbers-network/monitoring/disk-check.sh

# Configure environment variables
sudo tee /etc/environment.d/disk-check.conf > /dev/null <<'EOF'
ALERT_EMAIL=ops@example.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
DISK_WARNING_PCT=80
DISK_CRITICAL_PCT=90
EOF

# Add cron job (every 15 minutes)
(crontab -l 2>/dev/null; echo "*/15 * * * * /opt/numbers-network/monitoring/disk-check.sh >> /var/log/disk-check.log 2>&1") | crontab -
```

### Option 2 — GCP Cloud Monitoring alerting policies

Use `monitoring/setup-gcp-disk-alerts.sh` to provision GCP-native alerts:

```bash
export GCP_PROJECT=your-gcp-project-id
export ALERT_EMAIL=ops@example.com
# Optional Slack:
# export SLACK_CHANNEL_NAME=numbers-ops
# export SLACK_AUTH_TOKEN=xoxb-...

bash monitoring/setup-gcp-disk-alerts.sh
```

> **Note**: The GCP script requires the [Ops Agent](https://cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/installation)
> to be installed on each instance to report disk metrics. Without it, the GCP
> monitoring metric `agent.googleapis.com/disk/percent_used` will not be populated.

---

## Incident History

| Date       | Instance                    | Disk % | Event                                | Resolution         |
|------------|-----------------------------|--------|--------------------------------------|--------------------|
| 2026-03-15 | numbers-mainnet-validator-1 | 97%    | Auto-shutdown triggered by OS        | Manual cleanup     |
| 2026-03-17 | numbers-testnet-validator-3 | 96%    | CRITICAL — approaching auto-shutdown | Disk expansion + pruning |

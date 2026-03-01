# Disaster Recovery Runbook

This document provides step-by-step procedures for recovering a Numbers Network validator from various failure scenarios. Follow these instructions carefully; all commands assume a Linux environment with `bash`, `tar`, `jq`, and `curl` available.

---

## Table of Contents

1. [Restoring a Validator from Backup](#1-restoring-a-validator-from-backup)
2. [Rolling Back a Failed Validator Update](#2-rolling-back-a-failed-validator-update)
3. [Key Compromise and Rotation](#3-key-compromise-and-rotation)
4. [Emergency Subnet Governance Actions](#4-emergency-subnet-governance-actions)
5. [Communication Procedures](#5-communication-procedures)

---

## 1. Restoring a Validator from Backup

### When to Use
- Validator state is corrupted or lost.
- Host machine needs to be rebuilt.
- Migrating the validator to a new host.

### Prerequisites
- Access to the backup archive produced by `chains/backup-validator.sh` (e.g. `<hostname>.tar.gz` or a `validator-backup-pre-*.tar.gz` from `~/validator-backups/`).
- AvalancheGo installed at the target version.

### Steps

1. **Stop the running validator** (if still running):
   ```sh
   pkill -f avalanchego || true
   ```

2. **Verify the backup archive integrity** before restoring:
   ```sh
   tar -tzf /path/to/backup.tar.gz > /dev/null && echo "Archive OK" || echo "Archive CORRUPT – do not restore"
   ```
   > If the archive is corrupt, locate an older backup and repeat this check.

3. **Restore the staking keys and configs**:
   ```sh
   cd ~
   tar xzf /path/to/backup.tar.gz
   ```
   This restores `.avalanchego/staking/` (containing `staker.crt` and `staker.key`).

4. **Confirm the restored files**:
   ```sh
   ls -la ~/.avalanchego/staking/
   # Expected: staker.crt  staker.key
   ```

5. **Start the validator**:
   ```sh
   cd ~/avalanchego-v<VERSION>
   ./run.sh
   ```

6. **Verify health** (wait up to 60 s for the node to boot):
   ```sh
   for i in $(seq 1 12); do
     response=$(curl -sf -X POST --data '{"jsonrpc":"2.0","id":1,"method":"health.health"}' \
       -H 'content-type:application/json;' 127.0.0.1:9650/ext/health)
     echo "$response" | grep -q '"healthy":true' && echo "Node healthy" && break
     echo "Waiting... ($((i*5))s elapsed)"
     sleep 5
   done
   ```

---

## 2. Rolling Back a Failed Validator Update

### When to Use
- After running `update-validator-mainnet.sh` or `update-validator-testnet.sh`, the validator fails to start or become healthy.

### Automated Rollback

The update scripts create a versioned backup before applying changes. If the health check fails the script initiates a rollback automatically. You can also trigger it manually:

```sh
# Mainnet
./chains/update-validator-mainnet.sh --rollback

# Testnet
./chains/update-validator-testnet.sh --rollback
```

The `--rollback` flag:
1. Locates the most recent `~/validator-backups/validator-backup-pre-<VERSION>-*.tar.gz`.
2. Verifies archive integrity.
3. Extracts the previous binary and plugin into `$HOME`.
4. Prints instructions to restart the validator manually.

### Manual Rollback

If the automated rollback fails:

1. **List available backups**:
   ```sh
   ls -lt ~/validator-backups/
   ```

2. **Restore from the most recent pre-update backup**:
   ```sh
   tar -tzf ~/validator-backups/<backup-file>.tar.gz && \
   tar xzf ~/validator-backups/<backup-file>.tar.gz -C ~
   ```

3. **Restore the plugin**:
   ```sh
   # Identify the VM_ID from the update script and replace below
   cp ~/.avalanchego/plugins/<VM_ID>.bak ~/.avalanchego/plugins/<VM_ID> 2>/dev/null || true
   ```

4. **Restart the old version**:
   ```sh
   cd ~/avalanchego-v<PREVIOUS_VERSION>
   ./run.sh
   ```

---

## 3. Key Compromise and Rotation

### When to Use
- Staking key (`staker.key`) or TLS certificate (`staker.crt`) is believed to be exposed.
- Server hosting the validator was compromised.

> **Warning**: Rotating the staking key changes the Node ID. The old Node ID must be removed from the subnet and the new one added through governance.

### Steps

1. **Immediately stop the validator**:
   ```sh
   pkill -f avalanchego
   ```

2. **Isolate the host** (firewall off inbound/outbound traffic if possible) to prevent further misuse of the compromised key.

3. **Back up the compromised keys** for forensic purposes:
   ```sh
   cp -r ~/.avalanchego/staking/ ~/compromised-staking-keys-$(date +%Y%m%d%H%M%S)/
   ```

4. **Generate new staking credentials** by removing the old ones (AvalancheGo auto-generates on next start):
   ```sh
   rm ~/.avalanchego/staking/staker.key ~/.avalanchego/staking/staker.crt
   ```

5. **Start the validator once** to generate a new Node ID, then stop it:
   ```sh
   cd ~/avalanchego-v<VERSION>
   ./run.sh &
   sleep 10
   NEW_NODE_ID=$(curl -sf -X POST --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeID"}' \
     -H 'content-type:application/json;' 127.0.0.1:9650/ext/info | jq -r '.result.nodeID')
   echo "New Node ID: ${NEW_NODE_ID}"
   pkill -f avalanchego
   ```

6. **Submit a governance transaction** to replace the compromised validator with the new Node ID (see [Section 4](#4-emergency-subnet-governance-actions)).

7. **Secure the new keys**:
   ```sh
   chmod 600 ~/.avalanchego/staking/staker.key ~/.avalanchego/staking/staker.crt
   ```

8. **Create an immediate backup**:
   ```sh
   ./chains/backup-validator.sh
   ```

---

## 4. Emergency Subnet Governance Actions

### When to Use
- Removing a compromised or unresponsive validator from the subnet.
- Adding a replacement validator after key rotation.

### Prerequisites
- Access to the `subnet-cli` tool (see `chains/install-subnet-cli.sh`).
- Control key for the subnet.

### Remove a Validator from the Subnet

```sh
subnet-cli remove validator \
  --node-id=<COMPROMISED_NODE_ID> \
  --subnet-id=<SUBNET_ID> \
  --private-key-path=<CONTROL_KEY_PATH>
```

### Add a Replacement Validator

```sh
subnet-cli add validator \
  --node-id=<NEW_NODE_ID> \
  --subnet-id=<SUBNET_ID> \
  --stake-amount=<AMOUNT_NAVAX> \
  --start-time=<START_UNIX_TIMESTAMP> \
  --end-time=<END_UNIX_TIMESTAMP> \
  --private-key-path=<CONTROL_KEY_PATH>
```

> Refer to `chains/mainnet/subnet-cli.md` and `subnet-cli/` for additional context and network-specific parameters.

### Verify Current Validators

```sh
cd ~/avalanchego-api-scripts/api
# Mainnet
./platform.getCurrentValidators.sh 2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ | jq .
# Testnet
./platform.getCurrentValidators.sh 81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe | jq .
```

---

## 5. Communication Procedures

### Internal Escalation

| Severity | Trigger | Action |
|----------|---------|--------|
| P1 – Critical | Validator down > 5 min or key compromise | Page on-call engineer immediately; open incident channel |
| P2 – High | Health check failing; rollback in progress | Notify team lead within 15 min |
| P3 – Medium | Planned maintenance or non-critical degradation | Team notification within 1 h |

### Incident Channel

1. Open a dedicated incident channel (e.g. `#incident-YYYYMMDD-validator`).
2. Designate an **Incident Commander** and a **Scribe**.
3. Post updates every 15 minutes until resolved.

### External Communication

- If the validator outage affects public-facing RPC endpoints or causes visible chain disruption, post a status update to the official communication channels (Discord, Twitter/X) within 30 minutes.
- Template:
  > **[STATUS UPDATE]** We are aware of an issue affecting the Numbers Network validator. Our team is actively investigating. We will provide updates every 30 minutes. ETA for resolution: TBD.

### Post-Incident Review

Within 48 hours of resolution:
1. Document root cause, timeline, and impact.
2. Identify action items to prevent recurrence.
3. Update this runbook if procedures need adjustment.

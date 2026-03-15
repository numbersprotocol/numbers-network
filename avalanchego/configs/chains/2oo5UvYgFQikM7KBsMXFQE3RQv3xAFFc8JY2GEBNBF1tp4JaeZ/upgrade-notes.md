# Upgrade Notes — Numbers Testnet (2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ)

This file documents the human-readable meaning of each Unix timestamp and upgrade
action defined in `upgrade.json` for the Numbers Testnet subnet.

> **Warning:** Incorrect timestamps in `upgrade.json` can cause consensus failures.
> Always verify timestamps are sequential and in the future before deployment.
> See [upgrade scheduling process](#upgrade-scheduling-process) below.

---

## Timestamp Reference

| Unix Timestamp | UTC Date/Time               | Description                                                         |
|---------------:|-----------------------------|---------------------------------------------------------------------|
| `1762510500`   | 2025-11-07 10:15:00 UTC     | Activate Granite network upgrade (`graniteTimestamp`)               |
| `1767786600`   | 2026-01-07 11:50:00 UTC     | Re-enable `contractDeployerAllowList` with updated admin address    |
| `1767787800`   | 2026-01-07 12:10:00 UTC     | Disable `contractDeployerAllowList` precompile                      |

---

## Upgrade Details

### 1 — Granite Network Upgrade (`graniteTimestamp: 1762510500`)

**Date:** 2025-11-07 10:15:00 UTC

**Purpose:**  
Activates the Granite network upgrade on Numbers Testnet via the
`networkUpgradeOverrides` mechanism. This override is used to schedule the Granite
AvalancheGo protocol upgrade for this specific subnet at a time that aligns with
testnet operations (as opposed to the default timestamp inherited from AvalancheGo).

**References:**  
See AvalancheGo release notes for the Granite upgrade features and changes.

---

### 2 — Re-enable Contract Deployer Allow List (`blockTimestamp: 1767786600`)

**Date:** 2026-01-07 11:50:00 UTC

**Purpose:**  
Re-enables the `contractDeployerAllowList` precompile with the updated admin address
`0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5`. This sets the precompile back to an
active state with a new admin before the subsequent disable step.

**Admin address:** `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5` (EIP-55 checksummed)

---

### 3 — Disable Contract Deployer Allow List (`blockTimestamp: 1767787800`)

**Date:** 2026-01-07 12:10:00 UTC

**Purpose:**  
Disables the `contractDeployerAllowList` precompile 20 minutes after step 2,
allowing permissionless contract deployment on Numbers Testnet.

---

## Upgrade Scheduling Process

1. **Propose:** Open a governance discussion with the proposed timestamp and rationale.
2. **Validate:** Confirm the timestamp is in the future, sequential with prior upgrades,
   and consistent across all affected chains.
3. **Distribute:** Update `upgrade.json` on all nodes (validators and archive nodes)
   at least 24 hours before activation.
4. **Verify:** After the activation block, confirm on-chain state reflects the upgrade.

### Timestamp Validation Checklist

- [ ] Timestamp is in Unix seconds (not milliseconds)
- [ ] Timestamp is in the future at deployment time
- [ ] Timestamp is strictly greater than all preceding `blockTimestamp` values
- [ ] Same timestamp is used consistently across all node configurations
- [ ] Human-readable date/time confirmed with `date -d @<timestamp>` or
      `python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(<timestamp>))"`

---

## Related Files

- `upgrade.json` — Machine-readable upgrade configuration consumed by AvalancheGo
- `chains/testnet/genesis.json` — Genesis configuration for Numbers Testnet

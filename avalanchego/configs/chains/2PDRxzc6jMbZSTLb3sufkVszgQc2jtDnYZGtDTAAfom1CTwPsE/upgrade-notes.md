# Upgrade Notes — Numbers Mainnet (2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE)

This file documents the human-readable meaning of each Unix timestamp and upgrade
action defined in `upgrade.json` for the Numbers Mainnet subnet.

> **Warning:** Incorrect timestamps in `upgrade.json` can cause consensus failures.
> Always verify timestamps are sequential and in the future before deployment.
> See [upgrade scheduling process](#upgrade-scheduling-process) below.

---

## Timestamp Reference

| Unix Timestamp | UTC Date/Time               | Description                                      |
|---------------:|-----------------------------|--------------------------------------------------|
| `1767789000`   | 2026-01-07 12:30:00 UTC     | Disable `contractDeployerAllowList` precompile   |

---

## Upgrade Details

### 1 — Disable Contract Deployer Allow List (`blockTimestamp: 1767789000`)

**Date:** 2026-01-07 12:30:00 UTC

**Purpose:**  
Disables the `contractDeployerAllowList` precompile, allowing permissionless contract
deployment on Numbers Mainnet. Once disabled, any address can deploy smart contracts
without prior allow-list approval.

**Action required on validators:**  
Deploy the updated `upgrade.json` to all validator and archive nodes before the
activation timestamp. Nodes must be restarted to pick up the new configuration.

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
- `chains/mainnet/genesis.json` — Genesis configuration for Numbers Mainnet

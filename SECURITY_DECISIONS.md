# Security Decisions

This document records significant security-related configuration decisions for the Numbers Network, providing rationale and context for auditors, operators, and future maintainers.

---

## [2026-01-07] Disable `contractDeployerAllowList` — Open Contract Deployment

### Decision

The `contractDeployerAllowList` precompile has been disabled on both mainnet (Jade) and testnet (Snow), transitioning Numbers Network from a permissioned to a fully permissionless contract deployment model.

### Affected Networks

| Network  | Chain ID | Blockchain ID | Activation Timestamp | Activation Date (UTC) |
|----------|----------|---------------|---------------------|-----------------------|
| Mainnet (Jade) | 10507 | `2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE` | `1767789000` | 2026-01-07 12:30 UTC |
| Testnet (Snow) | 10508 | `2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ` | `1767787800` | 2026-01-07 12:10 UTC |

Configuration files:
- [`avalanchego/configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/upgrade.json`](avalanchego/configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/upgrade.json)
- [`avalanchego/configs/chains/2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/upgrade.json`](avalanchego/configs/chains/2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/upgrade.json)

### Prior State

Since genesis (block timestamp `0`), contract deployment was restricted to allow-listed admin addresses only:

| Network  | Genesis Admin Address |
|----------|-----------------------|
| Mainnet (Jade) | `0x8cba0477d89394e6d8ad658e11d52113a2da4ab2` |
| Testnet (Snow) | `0x8cba0477d89394e6d8ad658e11d52113a2da4ab2` |

### Rationale

Numbers Network has matured to the point where open, permissionless contract deployment supports the project's goal of becoming a public, EVM-compatible infrastructure for digital media provenance. Restricting deployment to a small set of admin addresses was a bootstrapping measure to maintain network stability during the early launch phase. Removing this restriction:

1. **Enables ecosystem growth** — Third-party developers can deploy contracts without requesting admin access.
2. **Aligns with EVM norms** — Standard Ethereum and EVM-compatible networks do not restrict contract deployment by default.
3. **Reduces admin dependency** — Eliminates a single point of failure where network utility depended on admin availability.

### Security Considerations

- Any address can now deploy arbitrary smart contracts on both mainnet and testnet. This is consistent with the standard EVM security model and places responsibility on users to verify contracts they interact with.
- The Numbers Network block explorer can be used to inspect deployed contracts. Operators and community members are encouraged to monitor for malicious deployments.
- Other access controls (e.g., `contractNativeMinterConfig`) remain in place and are unaffected by this change.

---

## [2026-01-07] Testnet-only `networkUpgradeOverrides` — Granite Timestamp

### Decision

The testnet (`Snow`) `upgrade.json` includes a `networkUpgradeOverrides` section that overrides the Granite network upgrade timestamp. This override does **not** exist on mainnet.

### Details

```json
"networkUpgradeOverrides": {
  "graniteTimestamp": 1762510500
}
```

| Field | Value | Human-readable (UTC) |
|-------|-------|----------------------|
| `graniteTimestamp` | `1762510500` | 2025-11-06 ~09:36 UTC |

### Rationale

The Granite upgrade override was applied to testnet ahead of the mainnet schedule in order to validate compatibility of the subnet-evm Granite features before rolling them out on mainnet. Testnet serves as the proving ground for network-level upgrades. Once the Granite upgrade was confirmed stable on testnet, no override was required on mainnet as it followed the standard Avalanche upgrade schedule.

This intentional asymmetry between testnet and mainnet is expected and follows the standard Numbers Network practice of staging upgrades on testnet before mainnet deployment.

### Testnet Upgrade Sequence (2026-01-07)

The testnet `upgrade.json` also shows the two-step process used to transition the deployer allow list:

| Step | Timestamp | Date (UTC) | Action |
|------|-----------|------------|--------|
| 1 | `1767786600` | 2026-01-07 ~11:50 UTC | Re-enable allow list with new admin `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5` |
| 2 | `1767787800` | 2026-01-07 ~12:10 UTC | Disable allow list (open deployment) |

Step 1 was included to transfer admin control to an updated address before the final disable, ensuring a clean state transition. Mainnet skipped Step 1 since the original genesis admin (`0x8cba0477d89394e6d8ad658e11d52113a2da4ab2`) was already current.

# Upgrade History

This document records the history of precompile upgrades applied to Numbers Network chains, including the rationale, execution date, and outcome for each entry. Refer to the corresponding `upgrade.json` files for the machine-readable configuration.

---

## Numbers Testnet — Snow

**Chain ID:** `2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ`
**Subnet ID:** `81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe`

### Network Upgrade Overrides

| Field | Value | Date (UTC) |
|---|---|---|
| `graniteTimestamp` | `1762510500` | 2025-11-07 10:15:00 |

**Rationale:** Overrides the Granite network upgrade activation time for the Numbers Testnet. Applied to align the testnet's Granite hard fork with the intended schedule independently of the default Avalanche network upgrade timeline.

**Outcome:** Granite upgrade activated successfully on the Numbers Testnet at the specified timestamp.

---

### Precompile Upgrades

#### 1. Enable `contractDeployerAllowList` (temporary)

| Field | Value | Date (UTC) |
|---|---|---|
| `blockTimestamp` | `1767786600` | 2026-01-07 11:50:00 |
| `adminAddresses` | `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5` | — |

**Rationale:** Temporarily enabled the contract deployer allow list on the Numbers Testnet to test permissioned deployment controls. The admin address was granted the ability to manage deployment permissions during the test window.

**Outcome:** Allow list activated and verified. The precompile was intentionally disabled 20 minutes later (see entry below) after confirming the feature behaved as expected.

---

#### 2. Disable `contractDeployerAllowList`

| Field | Value | Date (UTC) |
|---|---|---|
| `blockTimestamp` | `1767787800` | 2026-01-07 12:10:00 |
| `disable` | `true` | — |

**Rationale:** Disabled the contract deployer allow list 20 minutes after activation. This concluded the temporary test of permissioned deployment controls, restoring open contract deployment on the Numbers Testnet.

**Outcome:** Allow list disabled successfully. The Numbers Testnet is currently operating with unrestricted contract deployment.

---

## Numbers Mainnet — Jade

**Chain ID:** `2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE`
**Subnet ID:** `2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ`

### Precompile Upgrades

#### 1. Disable `contractDeployerAllowList`

| Field | Value | Date (UTC) |
|---|---|---|
| `blockTimestamp` | `1767789000` | 2026-01-07 12:30:00 |
| `disable` | `true` | — |

**Rationale:** The Numbers Mainnet launched with the contract deployer allow list enabled (configured at genesis) to maintain controlled deployment during the initial launch period. Once the network was stable and the ecosystem was ready for open deployment, the allow list was disabled to allow any address to deploy contracts without permission.

**Outcome:** Allow list disabled successfully. The Numbers Mainnet is currently operating with unrestricted contract deployment.

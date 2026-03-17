# AvalancheGo Configuration Files

Reference configuration files for Numbers Network nodes running on Avalanche infrastructure.

## Directory Structure

```
configs/chains/
├── C/                          # Avalanche C-Chain configuration
│   └── config.json            # Pruning enabled for storage optimization
├── 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/  # Numbers Testnet (Snow)
│   ├── config.json            # Archive node configuration
│   ├── config-validator.json  # Validator node configuration
│   └── upgrade.json           # Network upgrade schedule (precompile upgrades)
└── 2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/  # Numbers Mainnet (Jade)
    ├── config.json            # Archive node configuration
    ├── config-validator.json  # Validator node configuration
    └── upgrade.json           # Network upgrade schedule (precompile upgrades)
```

## Configuration Overview

### C-Chain Configuration
The C-Chain configuration enables pruning to optimize storage usage:
- Keeps only active state (significantly reduced from archival mode)
- Allows migration from archival to pruning mode
- Disables transaction indexing for additional space savings

### Numbers Network Configurations

**Archive Nodes** (`config.json`):
- Full historical data retention
- Pruning disabled for complete blockchain history
- Supports historical queries and provenance lookups

**Validator Nodes** (`config-validator.json`):
- Pruning enabled for optimal storage
- Maintains recent state for validation
- Reduced disk space requirements

### Network Upgrade Configurations (`upgrade.json`)

Each chain directory contains an `upgrade.json` file that schedules time-based precompile upgrades using Unix timestamps. These files control when specific EVM precompile features are enabled or disabled on the network.

**Mainnet (`2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/upgrade.json`):**
- Disables `contractDeployerAllowList` at timestamp `1767789000` (2026-01-07 12:30 UTC), opening contract deployment to all addresses.

**Testnet (`2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/upgrade.json`):**
- Includes a `networkUpgradeOverrides` for the Granite protocol upgrade (`graniteTimestamp: 1762510500` / 2025-11-06), applied ahead of mainnet to validate compatibility.
- Performs a two-step transition: re-enables `contractDeployerAllowList` with an updated admin at `1767786600`, then disables it at `1767787800` (2026-01-07 12:10 UTC).

For the security rationale behind these changes, see [`SECURITY_DECISIONS.md`](../../../SECURITY_DECISIONS.md) at the repository root.

## Usage

Copy the appropriate configuration files to your AvalancheGo installation:

```bash
# Example: Deploy C-Chain config
cp configs/chains/C/config.json ~/.avalanchego/configs/chains/C/config.json

# Example: Deploy Numbers Mainnet validator config
cp configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/config-validator.json \
   ~/.avalanchego/configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/config.json
```

Restart your node after applying configuration changes.

## Storage Optimization

These configurations are designed to optimize storage usage while maintaining appropriate data retention for different node types:

- **Validators**: Minimal storage footprint with pruning enabled
- **Archive Nodes**: C-Chain pruning with full Numbers Network history

For more information about AvalancheGo configuration options, see the [official documentation](https://docs.avax.network/nodes/configure/avalanchego-config-flags).

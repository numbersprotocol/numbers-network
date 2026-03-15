# AvalancheGo Configuration Files

Reference configuration files for Numbers Network nodes running on Avalanche infrastructure.

## Directory Structure

```
configs/chains/
├── C/                          # Avalanche C-Chain configuration
│   └── config.json            # Pruning enabled for storage optimization
├── 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/  # Numbers Testnet
│   ├── config.json            # Archive node configuration
│   ├── config-validator.json  # Validator node configuration
│   ├── upgrade.json           # Network upgrade schedule (machine-readable)
│   └── upgrade-notes.md       # Upgrade timestamp documentation (human-readable)
└── 2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/  # Numbers Mainnet
    ├── config.json            # Archive node configuration
    ├── config-validator.json  # Validator node configuration
    ├── upgrade.json           # Network upgrade schedule (machine-readable)
    └── upgrade-notes.md       # Upgrade timestamp documentation (human-readable)
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

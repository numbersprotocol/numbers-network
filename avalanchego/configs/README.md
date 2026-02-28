# AvalancheGo Configuration Files

Reference configuration files for Numbers Network nodes running on Avalanche infrastructure.

## Directory Structure

```
configs/chains/
├── C/                          # Avalanche C-Chain configuration
│   └── config.json            # Pruning enabled for storage optimization
├── 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/  # Numbers Testnet
│   ├── config.json            # Archive node configuration
│   └── config-validator.json  # Validator node configuration
└── 2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/  # Numbers Mainnet
    ├── config.json            # Archive node configuration
    └── config-validator.json  # Validator node configuration
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
- Exposes only `eth`, `eth-filter`, `net`, and `web3` APIs

**Validator Nodes** (`config-validator.json`):
- Pruning enabled for optimal storage
- Maintains recent state for validation
- Reduced disk space requirements

## Security Recommendations

### API Exposure
- **Do NOT** add `debug-tracer`, `internal-eth`, `internal-blockchain`, `internal-transaction`, or `internal-tx-pool` to the `eth-apis` list in publicly accessible node configurations. These APIs expose sensitive internal node state and tracing capabilities.
- If debug/internal APIs are required for operational purposes, restrict their use to nodes that are **not** exposed to the public internet (e.g., behind a firewall or VPN).
- When running AvalancheGo, bind `--http-host` to `127.0.0.1` instead of `0.0.0.0` to prevent unintended public exposure of the RPC endpoint. Only expose via a reverse proxy with appropriate access controls.

### Precompile Admin Addresses
- Avoid using a single EOA (externally owned account) as the admin for multiple precompiles (`contractDeployerAllowListConfig`, `contractNativeMinterConfig`, `feeManagerConfig`). A single compromised key would grant full control over token minting, fee management, and contract deployment simultaneously.
- Use a **multisig wallet** (e.g., Gnosis Safe) as the admin address for each precompile.
- Use **separate admin addresses** for each precompile to limit blast radius in case of key compromise.
- Consider adding a **timelock contract** for critical admin operations to allow time for intervention in case of compromise.

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

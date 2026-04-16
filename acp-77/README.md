# ACP-77: Subnet to L1 Conversion

Scripts for converting Numbers Network from Avalanche permissioned Subnet to L1, as defined in [ACP-77](https://build.avax.network/docs/acps/77-reinventing-subnets).

Tracking issue: [#144](https://github.com/numbersprotocol/numbers-network/issues/144)

## Why Convert?

| Before (Subnet) | After (L1) |
|---|---|
| Validators must stake 2,000 AVAX on Primary Network | No Primary Network staking required |
| Validator changes require subnet owner private key on P-Chain | On-chain ValidatorManager contract |
| Must sync full P/X/C-Chain | Reduced sync requirements |
| `AddSubnetValidatorTx` on P-Chain | `RegisterL1ValidatorTx` via Warp messaging |

## Network Support

All scripts default to **testnet**. Set `NETWORK=mainnet` to target mainnet.

| Parameter | Testnet (Snow) | Mainnet (Jade) |
|---|---|---|
| Chain ID | 10508 | 10507 |
| Chain Name | captevm | numbersevm |
| Subnet ID | `81vK49...CvFUWQe` | `2gHgAg...K1SzSQ` |
| Blockchain ID | `2oo5Uv...oAmEwj` | `2PDRxz...CTwPsE` |
| RPC | testnetrpc.num.network | mainnetrpc.num.network |
| Avalanche Network | fuji | mainnet |

## Prerequisites

- [Avalanche CLI](https://build.avax.network/docs/tooling/avalanche-cli/install-avalanche-cli)
- [Foundry](https://getfoundry.sh/) (for deploying ValidatorManager; `02b` can auto-install)
- Subnet owner private key
- Deployer private key with tokens on the L1 chain (for ValidatorManager deployment gas)
- AVAX on P-Chain (~1-2 AVAX for conversion + validator fees)
- `python3`, `curl`, `jq` on the operator machine

## Scripts

Run scripts in order. Each script displays its configuration and next steps.

```
# Testnet (default)
./00-install-avalanche-cli.sh

# Mainnet
NETWORK=mainnet ./00-install-avalanche-cli.sh
```

### Phase 0: Prerequisites

| Script | Description | Where to Run |
|---|---|---|
| `00-install-avalanche-cli.sh` | Install Avalanche CLI | Operator machine |
| `01-import-blockchain.sh` | Import existing blockchain into CLI | Operator machine |
| `02-backup-node.sh` | Backup staking keys and configs | Each validator node |

### Phase 1-3: Conversion

| Script | Description | Where to Run |
|---|---|---|
| `02b-deploy-validator-manager.sh` | Deploy ValidatorManager contract on-chain (requires Foundry) | Operator machine |
| `03-convert-to-l1.sh` | Execute ConvertSubnetToL1Tx via `blockchain convert` (irreversible) | Operator machine |
| `04-init-validator-manager.sh` | Initialize ValidatorManager contract | Operator machine |
| `05-verify-conversion.sh` | Verify conversion status and validators | Anywhere |

### Post-Conversion

| Script | Description | Where to Run |
|---|---|---|
| `06-add-validator.sh` | Add a new L1 validator | Operator machine |
| `07-remove-validator.sh` | Remove an L1 validator | Operator machine |
| `08-cleanup-node.sh` | Stop node, delete DB, clean disk, restart | Target node |

## Step-by-Step Guide

### 1. Prepare (Operator Machine)

```bash
# Install Avalanche CLI
./00-install-avalanche-cli.sh

# Import the blockchain
./01-import-blockchain.sh
```

### 2. Backup (Each Node)

```bash
# Copy this directory to each node and run:
./02-backup-node.sh
```

### 3. Deploy ValidatorManager (Operator Machine)

```bash
# Deploy the ValidatorManager contract on the L1 chain
# Requires Foundry and a private key with tokens for gas
DEPLOYER_KEY=0xYOUR_PRIVATE_KEY ./02b-deploy-validator-manager.sh
```

### 4. Import PoA Controller Key (Operator Machine)

```bash
# Import the private key that will control the ValidatorManager (add/remove validators).
# The CLI ships with only "ewoq" (a test-only key) — you must import your own key.

# Save your hex private key (without 0x prefix) to a temp file
echo 'YOUR_PRIVATE_KEY_HEX' > /tmp/poa-controller.pk

# Import into Avalanche CLI
avalanche key create poa-controller --file /tmp/poa-controller.pk

# Verify import
avalanche key list

# Clean up
rm /tmp/poa-controller.pk
```

### 5. Convert (Operator Machine)

```bash
# Convert subnet to L1 (IRREVERSIBLE)
# Uses the ValidatorManager address from step 3 automatically
./03-convert-to-l1.sh

# Initialize ValidatorManager contract
./04-init-validator-manager.sh

# Verify everything works
./05-verify-conversion.sh
```

### 6. Manage Validators (Operator Machine)

```bash
# Add a new validator
./06-add-validator.sh NodeID-XXXXX 0xBLS_PUBLIC_KEY 0xBLS_POP 1000

# Remove a validator
./07-remove-validator.sh NodeID-XXXXX
```

### 7. Clean Up Disk (On Target Node)

```bash
# Stop, clean DB, restart (node will re-sync)
./08-cleanup-node.sh
```

## Configuration

All network-specific configuration is in `env.sh`. Key variables:

```bash
NETWORK          # "testnet" (default) or "mainnet"
SUBNET_ID        # Avalanche Subnet ID
BLOCKCHAIN_ID    # Avalanche Blockchain ID
CHAIN_NAME       # Chain name registered in Avalanche CLI
CHAIN_ID         # EVM Chain ID
RPC_URL          # HTTPS RPC endpoint
P_CHAIN_API      # P-Chain API endpoint
```

## Important: `convert` vs `deploy`

The conversion script uses `avalanche blockchain convert`, **not** `avalanche blockchain deploy`:

| | `blockchain deploy` | `blockchain convert` |
|---|---|---|
| **Purpose** | Create and deploy a **new** blockchain | Convert an **existing** subnet to L1 |
| **P-Chain Tx** | CreateSubnetTx + CreateChainTx + ConvertSubnetToL1Tx | ConvertSubnetToL1Tx only |
| **Imported blockchains** | Rejected (`ImportedFromAPM` check) | Supported |
| **Use case** | New subnet from scratch | Existing running subnet upgrade |

The `import public` command sets `ImportedFromAPM=true` in the CLI sidecar, which causes `deploy` to fail with `"unable to deploy blockchains imported from a repo"`. The `convert` command does not have this restriction.

## References

- [ACP-77: Reinventing Subnets](https://build.avax.network/docs/acps/77-reinventing-subnets)
- [ValidatorManager Contract](https://build.avax.network/docs/avalanche-l1s/validator-manager/contract)
- [Subnet vs L1 Validators](https://build.avax.network/guides/subnet-vs-l1-validators)
- [Avalanche CLI Commands](https://build.avax.network/docs/tooling/cli-commands)
- [Etna Upgrade Changes](https://build.avax.network/blog/etna-changes)

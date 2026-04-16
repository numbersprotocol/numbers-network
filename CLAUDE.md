# Numbers Network - Project Context

## ACP-77: Subnet to L1 Conversion

Tracking issue: [#144](https://github.com/numbersprotocol/numbers-network/issues/144)

Scripts in `acp-77/` convert Numbers Network from permissioned Subnet to sovereign L1 (ACP-77).

### Deployed Contracts (Testnet - Snow)

| Contract | Address |
|---|---|
| ValidatorMessages (library) | `0xc5D4dF30D2477E36467526bE503e128eAE3Cf787` |
| ValidatorManager (impl) | `0xf1f675154d707BE455f122B49f24f36464Ce2e4f` |
| TransparentUpgradeableProxy (ValidatorManager) | `0x9Cbb4DF5cc25e3E8D4eCBb06B90c66e6e73AE51B` |

- **Deployer**: `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5`
- **Network**: Numbers Testnet (Snow), Chain ID 10508
- **RPC**: `https://testnetrpc.num.network`
- **Contract source**: [ava-labs/icm-services](https://github.com/ava-labs/icm-services)

### Conversion Progress

- [x] Phase 0: Import blockchain, backup nodes
- [x] Phase 1: Deploy ValidatorManager contract (`02b-deploy-validator-manager.sh`)
- [ ] Phase 2: Execute `ConvertSubnetToL1Tx` (`03-convert-to-l1.sh`) — use proxy address `0x9Cbb4DF5cc25e3E8D4eCBb06B90c66e6e73AE51B`
- [ ] Phase 3: Initialize ValidatorManager (`04-init-validator-manager.sh`)
- [ ] Post-conversion: Verify, manage validators, clean up disk

## Key Technical Notes

- Use `avalanche blockchain convert` (not `deploy`) for existing subnets — `deploy` rejects imported blockchains.
- ValidatorManager constructor arg: `ICMInitializable.Disallowed` (1) — implementation behind proxy.
- Foundry: `--constructor-args` is variadic — always place it **last** in `forge create` commands.
- Foundry: Use `FOUNDRY_LIBRARIES` env var for library linking — `forge create` recompiles from scratch and ignores `forge build` cache.

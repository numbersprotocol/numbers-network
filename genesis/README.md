# Genesis Files

This directory contains historical and reference genesis configurations for the Numbers Network. The canonical genesis files reside in `chains/<network>/`.

## Chain IDs

| Network | Chain ID |
|---------|----------|
| Mainnet | `10507`  |
| Testnet | `10508`  |
| Devnet  | `10509`  |

## Files

| File | Network | Chain ID | Description |
|------|---------|----------|-------------|
| `genesis.json` | Testnet | 10508 | Base testnet genesis configuration |
| `genesis-nativecoin-feemgr.json` | Testnet | 10508 | Testnet genesis with native coin minter and fee manager |
| `genesis-nativecoin-feemgr-feerecv.json` | Testnet | 10508 | Testnet genesis with native coin minter, fee manager, and fee receiver |

> ⚠️ These files use the **testnet** chain ID (10508). For production deployments, always use the genesis files in `chains/mainnet/`. Verify the chain ID before deploying.

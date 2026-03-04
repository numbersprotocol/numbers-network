# DEVELOPMENT ONLY

> ⚠️ **WARNING**: This directory contains devnet (development network) configuration files. Do NOT use these files for production (mainnet/testnet) deployments.

## Chain ID

- **Devnet chain ID**: `10509`
- **Testnet chain ID**: `10508`
- **Mainnet chain ID**: `10507`

Verify the chain ID in deployment scripts before proceeding. Using the wrong genesis file could result in funds allocated to the wrong address or network.

## Token Allocation

The devnet genesis allocates a large token balance for development and testing purposes only. This allocation is intentionally disproportionate and must never be used in production.

## Files

| File | Description |
|------|-------------|
| `genesis.json` | Devnet genesis configuration (DEVELOPMENT ONLY, chain ID 10509) |

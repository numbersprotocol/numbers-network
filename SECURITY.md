# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly by opening a [GitHub Security Advisory](https://github.com/numbersprotocol/numbers-network/security/advisories/new) rather than a public issue.

---

## Known Security Considerations

### 1. Single Admin Address for Precompile Configurations

**Risk: Critical**

The genesis configurations (`chains/mainnet/genesis.json`, `chains/testnet/genesis.json`, `chains/devnet/genesis.json`) currently use a **single EOA (externally owned account)** as the admin address for all three critical precompile configurations simultaneously:

- `contractDeployerAllowListConfig` — controls which addresses may deploy contracts
- `contractNativeMinterConfig` — controls native token minting
- `feeManagerConfig` — controls gas fee parameters

**Impact:** A single compromised private key grants the ability to mint unlimited native tokens (catastrophic inflation), manipulate gas fees (DoS or economic manipulation), and control contract deployment (censorship).

**Recommended Remediation (for new deployments):**

1. Deploy a **multisig wallet** (e.g., [Gnosis Safe](https://safe.global/)) and use its address as the admin for each precompile. Require M-of-N signers for any admin action.
2. Use **separate admin addresses** for each precompile to limit the blast radius in case of key compromise.
3. Deploy a **timelock contract** wrapping the admin address so that critical operations have a mandatory delay, allowing time for intervention if a key is compromised.

**For existing deployments:** Rotate the precompile admin addresses via an upgrade transaction from the current admin to a new multisig address, then renounce the original EOA admin role.

---

### 2. Debug and Internal APIs on Archive Nodes

**Risk: High**

Exposing `debug-tracer`, `internal-eth`, `internal-blockchain`, `internal-transaction`, and `internal-tx-pool` APIs on publicly accessible nodes can leak sensitive internal node state, enable denial-of-service via expensive trace calls, and expose transaction pool contents.

This has been **remediated** in this repository by removing these APIs from the archive node `eth-apis` lists:
- `avalanchego/configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/config.json` (mainnet archive)
- `avalanchego/configs/chains/2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/config.json` (testnet archive)

**Operational Guidance:**

- If debug/internal APIs are required for operational purposes (e.g., tracing transactions for debugging), host a **dedicated internal node** with these APIs enabled and place it **behind a firewall or VPN**, not exposed to the public internet.
- **Never** expose debug APIs through a public-facing reverse proxy (e.g., Nginx).
- Bind `--http-host` to `127.0.0.1` (localhost) instead of `0.0.0.0` unless you explicitly intend to expose the RPC to all network interfaces.
- If public RPC access is required, use a reverse proxy with **rate limiting and authentication** for any sensitive endpoints.

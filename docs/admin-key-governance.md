# Admin Key Governance

This document describes the admin addresses used to control precompile configurations
across Numbers Network environments, along with key management procedures and
emergency access protocols.

> **Security Notice:** The addresses listed here control critical network precompiles
> (contract deployment allow-list, native minter, fee manager). Loss of access to
> the corresponding private keys can permanently prevent future precompile updates.

---

## Admin Addresses by Environment

### Mainnet

| Role           | Address (EIP-55)                             | Precompiles Controlled                                                        |
|----------------|----------------------------------------------|-------------------------------------------------------------------------------|
| Mainnet Admin  | `0x8CBa0477D89394e6D8AD658E11d52113a2DA4AB2` | `contractDeployerAllowList`, `contractNativeMinter`, `feeManager`             |

**Reference:** `chains/mainnet/genesis.json` lines 28–43

---

### Testnet

| Role           | Address (EIP-55)                             | Precompiles Controlled                                                        |
|----------------|----------------------------------------------|-------------------------------------------------------------------------------|
| Testnet Admin  | `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5` | `contractDeployerAllowList`, `contractNativeMinter`, `feeManager`             |

**Reference:** `chains/devnet/genesis.json` lines 26–42  
_(Numbers Testnet genesis does not configure precompile admin addresses at genesis;
they are set via `upgrade.json` post-genesis upgrades.)_

---

### Devnet

| Role           | Address (EIP-55)                             | Precompiles Controlled                                                        |
|----------------|----------------------------------------------|-------------------------------------------------------------------------------|
| Devnet Admin   | `0x63B7076FC0A914Af543C2e5c201df6C29FCC18c5` | `contractDeployerAllowList`, `contractNativeMinter`, `feeManager`             |

**Reference:** `chains/devnet/genesis.json` lines 26–42

---

## Address Format

All admin addresses **must** be represented in
[EIP-55 checksummed format](https://eips.ethereum.org/EIPS/eip-55) in documentation
and configuration files where supported. The checksummed form provides built-in typo
detection.

To convert a lowercase address to EIP-55:
```python
# Python with web3.py
from web3 import Web3
Web3.to_checksum_address("0x8cba0477d89394e6d8ad658e11d52113a2da4ab2")
```

---

## Key Management Procedures

### Who Holds the Keys

- **Mainnet admin key** (`0x8CBa0477...`): Held by the Numbers Protocol core team.
  Document the specific key custodian(s) in a separate internal access register
  (not committed to this repository).
- **Testnet/Devnet admin key** (`0x63B7076F...`): Held by the Numbers Protocol
  development team for testing and staging operations.

### Recommended Storage

- Store private keys in hardware security modules (HSM) or hardware wallets
  (e.g., Ledger, Trezor) for mainnet operations.
- Never store unencrypted private keys on internet-connected machines.
- Use multi-signature schemes (e.g., Gnosis Safe) for mainnet precompile operations
  to require M-of-N approval before submitting transactions.

### Key Rotation

To rotate an admin key for a precompile:

1. Prepare a new address with the replacement key.
2. Using the current admin key, call the precompile's `setAdmin` (or equivalent)
   function to add the new address as an admin.
3. Verify the new admin address is active on-chain.
4. Revoke the old admin address using `revokeRole` (or equivalent).
5. Update this document and the relevant `genesis.json` / `upgrade.json` references.
6. Communicate the change to all node operators.

---

## Emergency Access Protocol

If the admin key holder is unavailable or the key is suspected to be compromised:

1. **Immediately assess impact:** Determine which precompiles are affected and
   whether any unauthorized transactions have been submitted.
2. **Activate backup access:** Use the secondary key holder (if a multi-sig is
   configured) to execute any urgent precompile changes.
3. **Schedule a network upgrade:** If the primary key is permanently lost,
   coordinate a network upgrade via `upgrade.json` to reassign admin addresses
   to a new key.
4. **Notify the community:** Publish a post-mortem and corrective action plan.

### Emergency Contact

Maintain an internal emergency contact list (separate from this repository) that
includes:
- Names and contact methods for each key custodian
- Secondary custodians for each environment
- Escalation path for multi-sig approval

---

## Audit Trail

Any changes to admin addresses (via precompile transactions or network upgrades)
should be:
- Documented in the relevant `upgrade-notes.md` file for the affected chain
- Announced in the Numbers Protocol governance forum
- Recorded with the transaction hash, block number, and date

---

## Related Files

| File | Description |
|------|-------------|
| `chains/mainnet/genesis.json` | Mainnet genesis with admin address |
| `chains/testnet/genesis.json` | Testnet genesis (no precompile admin at genesis; see `upgrade.json`) |
| `chains/devnet/genesis.json` | Devnet genesis with admin address |
| `avalanchego/configs/chains/2PDRxzc6.../upgrade-notes.md` | Mainnet upgrade timestamps |
| `avalanchego/configs/chains/2oo5UvYg.../upgrade-notes.md` | Testnet upgrade timestamps |
| `chains/backup-validator.sh` | Validator key backup script |

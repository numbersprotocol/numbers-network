# Contributing to Numbers Network

Thank you for your interest in contributing to Numbers Network!

## Getting Started

### Prerequisites

- [avalanchego](https://github.com/ava-labs/avalanchego/releases) — see `versions.env` for the supported version
- [subnet-evm](https://github.com/ava-labs/subnet-evm/releases) — see `versions.env` for the supported version
- Python 3.8+ with `pip` (for RPC tests)
- `jq` (for JSON formatting)
- `nginx` (for RPC provider setup)

### Setup

1. Clone the repository:

    ```sh
    git clone https://github.com/numbersprotocol/numbers-network.git
    cd numbers-network
    ```

2. Install Python dependencies:

    ```sh
    pip install -r requirements.txt
    ```

3. Source version variables when running update scripts:

    ```sh
    source versions.env
    ```

## Repository Structure

```
numbers-network/
├── api/                # AvalancheGo API helper scripts
│   └── env.sh          # Set URL for local node (default: 127.0.0.1:9650)
├── avalanchego/
│   └── configs/        # Chain and upgrade configuration files
├── chains/             # Validator update scripts and genesis files
│   ├── mainnet/        # Mainnet genesis
│   └── testnet/        # Testnet genesis files (canonical location)
├── rpc/                # RPC test scripts and Nginx configs
│   ├── mainnet/        # Mainnet Nginx config
│   └── testnet/        # Testnet Nginx config
├── subnet-cli/         # subnet-cli helper scripts
├── versions.env        # Canonical avalanchego and subnet-evm versions
└── requirements.txt    # Python dependencies
```

## API Scripts

The `api/` directory contains helper scripts for interacting with a local AvalancheGo node.

- All scripts source `api/env.sh` which sets `URL="127.0.0.1:9650"` by default.
- To target a different node, set the `URL` environment variable before running a script:

    ```sh
    URL="https://api.avax.network" ./api/platform.getCurrentValidators.sh <subnet-id>
    ```

## Running Tests

```sh
python3 rpc/rpc_test.py
python3 rpc/websocket_test.py
```

## Making Changes

1. Create a feature branch from `main`.
2. Make your changes, following the style of existing files.
3. For JSON files, normalize formatting with `jq .`:

    ```sh
    jq . file.json > /tmp/normalized.json && mv /tmp/normalized.json file.json
    ```

4. Update `versions.env` if software versions change.
5. Open a pull request with a clear description of the change.

## Code Style

- Shell scripts: use `#!/bin/bash` shebang; source `env.sh` for the node URL.
- JSON: 2-space indentation (normalized by `jq`).
- Python: follow PEP 8.

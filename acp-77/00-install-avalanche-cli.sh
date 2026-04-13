#!/bin/bash
#
# ACP-77 Phase 0: Install Avalanche CLI
#
# This script installs the latest Avalanche CLI, which is required
# for all subsequent ACP-77 conversion steps.
#
# Usage:
#   ./00-install-avalanche-cli.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

install_avalanche_cli() {
    echo "Step: install_avalanche_cli"
    curl -sSfL https://raw.githubusercontent.com/ava-labs/avalanche-cli/main/scripts/install.sh | sh -s
}

verify_installation() {
    echo "Step: verify_installation"
    if command -v avalanche &> /dev/null; then
        avalanche --version
        echo "Avalanche CLI installed successfully."
    else
        # The installer places the binary in ~/bin by default
        if [ -f "${HOME}/bin/avalanche" ]; then
            echo "Avalanche CLI installed at ~/bin/avalanche"
            echo "Add ~/bin to your PATH:"
            echo '  export PATH="${HOME}/bin:${PATH}"'
            "${HOME}/bin/avalanche" --version
        else
            echo "Error: Avalanche CLI installation failed."
            exit 1
        fi
    fi
}

show_next_action_reminder() {
    echo ""
    echo "Next steps:"
    echo "  1. Ensure 'avalanche' is in your PATH"
    echo "  2. Run ./01-import-blockchain.sh to import the existing blockchain"
}

main() {
    show_configs
    echo ""
    install_avalanche_cli
    verify_installation
    show_next_action_reminder
}

main

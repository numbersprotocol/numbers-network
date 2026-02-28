.PHONY: help setup test test-rpc test-ws fmt check-versions

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install Python dependencies
	pip install -r requirements.txt

test: test-rpc ## Run all tests

test-rpc: ## Test mainnet and testnet RPC connectivity
	python3 rpc/rpc_test.py

test-ws: ## Test mainnet and testnet WebSocket connectivity
	python3 rpc/websocket_test.py

fmt: ## Normalize JSON formatting in avalanchego config files
	@find avalanchego/configs -name "*.json" | while read f; do \
		jq . "$$f" > /tmp/normalized.json && mv /tmp/normalized.json "$$f"; \
		echo "Formatted: $$f"; \
	done

check-versions: ## Show configured software versions
	@. ./versions.env && echo "avalanchego: v$$AVALANCHEGO_VERSION" && echo "subnet-evm:  v$$SUBNET_EVM_VERSION"

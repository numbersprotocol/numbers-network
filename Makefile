.PHONY: help test-rpc test-ws backup

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

test-rpc: ## Run RPC connectivity and functionality tests
	cd rpc && python3 rpc_test.py

test-ws: ## Run WebSocket RPC tests
	cd rpc && python3 websocket_test.py

backup: ## Backup validator staking keys
	sh chains/backup-validator.sh

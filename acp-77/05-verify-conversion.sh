#!/bin/bash
#
# ACP-77 Phase 3: Verify L1 conversion status
#
# Queries the P-Chain to verify that the subnet has been converted
# and displays the current validator set.
#
# Usage:
#   ./05-verify-conversion.sh                  # Testnet (default)
#   NETWORK=mainnet ./05-verify-conversion.sh  # Mainnet

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

check_subnet_status() {
    echo "Step: check_subnet_status"

    SUBNET_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getSubnet\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    echo "Subnet status:"
    echo "${SUBNET_RESULT}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
r = d.get('result', {})
print(f'  isPermissioned:           {r.get(\"isPermissioned\", \"N/A\")}')
print(f'  conversionID:             {r.get(\"conversionID\", \"N/A\")}')
print(f'  managerChainID:           {r.get(\"managerChainID\", \"N/A\")}')
print(f'  managerAddress:           {r.get(\"managerAddress\", \"N/A\")}')
print(f'  controlKeys:              {r.get(\"controlKeys\", \"N/A\")}')
" 2>/dev/null || echo "${SUBNET_RESULT}" | python3 -m json.tool
}

check_validators() {
    echo ""
    echo "Step: check_validators"

    VALIDATORS_RESULT=$(curl -s -X POST --data "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"platform.getCurrentValidators\",
        \"params\":{\"subnetID\":\"${SUBNET_ID}\"},
        \"id\":1
    }" -H 'Content-Type: application/json' "${P_CHAIN_API}")

    echo "Current validators:"
    echo "${VALIDATORS_RESULT}" | python3 -c "
import json, sys, datetime
d = json.load(sys.stdin)
validators = d.get('result', {}).get('validators', [])
if not validators:
    print('  No validators found.')
else:
    print(f'  Total: {len(validators)} validator(s)')
    print()
    for i, v in enumerate(validators):
        print(f'  [{i+1}] NodeID:    {v.get(\"nodeID\", \"N/A\")}')
        print(f'      Weight:    {v.get(\"weight\", \"N/A\")}')
        print(f'      Connected: {v.get(\"connected\", \"N/A\")}')
        end_time = v.get('endTime', '')
        if end_time:
            try:
                end_dt = datetime.datetime.fromtimestamp(int(end_time))
                print(f'      EndTime:   {end_dt.isoformat()} ({end_time})')
            except:
                print(f'      EndTime:   {end_time}')
        print()
" 2>/dev/null || echo "${VALIDATORS_RESULT}" | python3 -m json.tool
}

check_chain_health() {
    echo "Step: check_chain_health"
    echo "Checking chain RPC health..."

    BLOCK_RESULT=$(curl -s -X POST --data '{
        "jsonrpc":"2.0",
        "method":"eth_blockNumber",
        "params":[],
        "id":1
    }' -H 'Content-Type: application/json' "${RPC_URL}")

    BLOCK_HEX=$(echo "${BLOCK_RESULT}" | python3 -c "import json,sys; print(json.load(sys.stdin)['result'])" 2>/dev/null || echo "unknown")
    if [ "${BLOCK_HEX}" != "unknown" ]; then
        BLOCK_DEC=$(python3 -c "print(int('${BLOCK_HEX}', 16))")
        echo "  RPC URL:       ${RPC_URL}"
        echo "  Current block: ${BLOCK_DEC} (${BLOCK_HEX})"
    else
        echo "  Warning: Could not query RPC endpoint ${RPC_URL}"
    fi
}

main() {
    show_configs
    echo ""
    check_subnet_status
    echo ""
    check_validators
    echo ""
    check_chain_health
}

main

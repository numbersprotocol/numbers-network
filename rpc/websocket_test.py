import asyncio
import json

import pytest
from websockets import connect


TESTNET_RPC_WS_ENDPOINT = 'wss://testnetrpc.num.network/ws'
MAINNET_RPC_WS_ENDPOINT = 'wss://mainnetrpc.num.network/ws'


async def subscribe_and_receive(rpc_ws_endpoint):
    async with connect(rpc_ws_endpoint) as ws:
        await ws.send('{"jsonrpc":"2.0", "id": 1, "method": "eth_subscribe", "params": ["logs", {"topics": []}]}')
        subscription_response = await ws.recv()
        return json.loads(subscription_response)


@pytest.mark.asyncio
async def test_testnet_ws_subscription():
    data = await subscribe_and_receive(TESTNET_RPC_WS_ENDPOINT)
    assert "result" in data, f"Expected subscription ID in response, got: {data}"


@pytest.mark.asyncio
async def test_mainnet_ws_subscription():
    data = await subscribe_and_receive(MAINNET_RPC_WS_ENDPOINT)
    assert "result" in data, f"Expected subscription ID in response, got: {data}"

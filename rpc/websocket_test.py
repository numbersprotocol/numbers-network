import asyncio
import json

from websockets import connect


TESTNET_RPC_WS_ENDPOINT='wss://testnetrpc.num.network/ws'
MAINNET_RPC_WS_ENDPOINT='wss://mainnetrpc.num.network/ws'


async def get_event(rpc_ws_endpoint):
    async with connect(rpc_ws_endpoint) as ws:
        await ws.send('{"jsonrpc":"2.0", "id": 1, "method": "eth_subscribe", "params": ["logs", {"topics": []}]}')
        subscription_response = await ws.recv()
        print(f'Testing WS endpoint {rpc_ws_endpoint}')
        print(subscription_response)

        while True:
            try:
                message = await asyncio.wait_for(ws.recv(), timeout=60)
                print(json.loads(message))
            except asyncio.TimeoutError:
                print(f"Timeout, no messages received for 60 seconds.")
            except Exception as e:
                print(f'Error: {e}')
                break  # This will only break the loop if there is an exception that's not a TimeoutError.


async def main():
    await asyncio.gather(
        get_event(rpc_ws_endpoint=TESTNET_RPC_WS_ENDPOINT),
        get_event(rpc_ws_endpoint=MAINNET_RPC_WS_ENDPOINT)
    )


if __name__ == '__main__':
    asyncio.run(main())

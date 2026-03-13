import argparse
import asyncio
import json
import sys
import time

from websockets import connect


TESTNET_RPC_WS_ENDPOINT = 'wss://testnetrpc.num.network/ws'
MAINNET_RPC_WS_ENDPOINT = 'wss://mainnetrpc.num.network/ws'

DEFAULT_TIMEOUT = 120
MIN_EVENTS = 1


async def get_event(rpc_ws_endpoint, total_timeout=DEFAULT_TIMEOUT, min_events=MIN_EVENTS):
    """
    Subscribe to Ethereum log events over a WebSocket connection.

    Listens for events until at least ``min_events`` have been received or
    ``total_timeout`` seconds have elapsed since the function started.

    Returns True if the minimum number of events was received, False otherwise.
    """
    events_received = 0
    deadline = time.monotonic() + total_timeout

    async with connect(rpc_ws_endpoint) as ws:
        await ws.send(
            '{"jsonrpc":"2.0", "id": 1, "method": "eth_subscribe", "params": ["logs", {"topics": []}]}'
        )
        subscription_response = await ws.recv()
        sub_data = json.loads(subscription_response)
        assert "error" not in sub_data, (
            f"Subscription error from {rpc_ws_endpoint}: {sub_data.get('error')}"
        )
        print(f'Testing WS endpoint {rpc_ws_endpoint}')
        print(subscription_response)

        while events_received < min_events:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                print(
                    f"Timeout reached for {rpc_ws_endpoint} after {total_timeout}s "
                    f"({events_received}/{min_events} events received)."
                )
                return False
            try:
                message = await asyncio.wait_for(ws.recv(), timeout=remaining)
                print(json.loads(message))
                events_received += 1
            except asyncio.TimeoutError:
                print(
                    f"Timeout reached for {rpc_ws_endpoint} after {total_timeout}s "
                    f"({events_received}/{min_events} events received)."
                )
                return False
            except Exception as e:
                print(f'Error receiving message from {rpc_ws_endpoint}: {e}')
                return False

    print(
        f"Success: received {events_received} event(s) from {rpc_ws_endpoint}."
    )
    return True


async def main(total_timeout=DEFAULT_TIMEOUT, min_events=MIN_EVENTS):
    results = await asyncio.gather(
        get_event(
            rpc_ws_endpoint=TESTNET_RPC_WS_ENDPOINT,
            total_timeout=total_timeout,
            min_events=min_events,
        ),
        get_event(
            rpc_ws_endpoint=MAINNET_RPC_WS_ENDPOINT,
            total_timeout=total_timeout,
            min_events=min_events,
        ),
        return_exceptions=True,
    )
    all_passed = all(r is True for r in results)
    for endpoint, result in zip(
        [TESTNET_RPC_WS_ENDPOINT, MAINNET_RPC_WS_ENDPOINT], results
    ):
        if isinstance(result, Exception):
            print(f"FAIL [{endpoint}]: {result}")
        elif not result:
            print(f"FAIL [{endpoint}]: did not receive enough events within timeout.")
    return all_passed


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="WebSocket RPC subscription test.")
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_TIMEOUT,
        help=f"Total timeout in seconds for each endpoint (default: {DEFAULT_TIMEOUT})",
    )
    parser.add_argument(
        "--min-events",
        type=int,
        default=MIN_EVENTS,
        help=f"Minimum number of events to receive per endpoint (default: {MIN_EVENTS})",
    )
    args = parser.parse_args()

    passed = asyncio.run(main(total_timeout=args.timeout, min_events=args.min_events))
    sys.exit(0 if passed else 1)

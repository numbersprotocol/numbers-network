#!/usr/bin/python3

import sys

import requests


MAINNET_RPC_URL = "https://mainnetrpc.num.network"
MAINNET_CHAIN_ID = 10507
TESTNET_RPC_URL = "https://testnetrpc.num.network"
TESTNET_CHAIN_ID = 10508


def test_connectivity(rpc_url):
    """Test that the RPC endpoint is reachable and returns HTTP 200."""
    try:
        response = requests.get(rpc_url)
        assert response.status_code == 200, (
            f"Node is not reachable, HTTP Status Code: {response.status_code}"
        )
        print(f"Node is reachable, HTTP Status Code: {response.status_code}")
    except AssertionError:
        raise
    except Exception as e:
        raise AssertionError(f"Connection failed, Error: {str(e)}") from e


def test_functionality(rpc_url):
    """Test that the RPC endpoint handles a web3_clientVersion request successfully."""
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1,
    }

    try:
        response = requests.post(rpc_url, json=payload)
        assert response.status_code == 200, (
            f"Unexpected HTTP status code: {response.status_code}"
        )
        response_data = response.json()
        assert "error" not in response_data, (
            f"RPC returned an error: {response_data['error']}"
        )
        assert "result" in response_data, (
            f"RPC response missing 'result' field: {response_data}"
        )
        print("RPC request successful, Response Data:", response_data)
    except AssertionError:
        raise
    except Exception as e:
        raise AssertionError(f"RPC request failed, Error: {str(e)}") from e


def test_chain_id(rpc_url, expected_chain_id):
    """Test that the RPC endpoint returns the expected chain ID."""
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "id": 1,
    }

    try:
        response = requests.post(rpc_url, json=payload)
        assert response.status_code == 200, (
            f"Unexpected HTTP status code: {response.status_code}"
        )
        response_data = response.json()
        assert "error" not in response_data, (
            f"RPC returned an error: {response_data['error']}"
        )
        assert "result" in response_data, (
            f"RPC response missing 'result' field: {response_data}"
        )
        returned_chain_id = int(response_data["result"], 16)
        assert returned_chain_id == expected_chain_id, (
            f"Chain ID mismatch: expected {expected_chain_id}, got {returned_chain_id}"
        )
        print("RPC request successful, Response Data:", response_data)
    except AssertionError:
        raise
    except Exception as e:
        raise AssertionError(f"RPC request failed, Error: {str(e)}") from e


def run_tests(rpc_url, chain_id, network_name):
    """Run all tests for the given network, returning True if all pass."""
    print(f"Testing {network_name} RPC")
    failed = False
    for test_fn, args in [
        (test_connectivity, (rpc_url,)),
        (test_functionality, (rpc_url,)),
        (test_chain_id, (rpc_url, chain_id)),
    ]:
        try:
            test_fn(*args)
        except AssertionError as e:
            print(f"FAIL [{test_fn.__name__}]: {e}")
            failed = True
    return not failed


if __name__ == '__main__':
    results = [
        run_tests(MAINNET_RPC_URL, MAINNET_CHAIN_ID, "Mainnet"),
        run_tests(TESTNET_RPC_URL, TESTNET_CHAIN_ID, "Testnet"),
    ]
    sys.exit(0 if all(results) else 1)

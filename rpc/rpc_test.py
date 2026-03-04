#!/usr/bin/python3

import requests
import json
from requests.exceptions import ConnectionError, Timeout, SSLError


MAINNET_RPC_URL = "https://mainnetrpc.num.network"
MAINNET_CHAIN_ID = 10507
TESTNET_RPC_URL = "https://testnetrpc.num.network"
TESTNET_CHAIN_ID = 10508


def test_connectivity(rpc_url):
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1
    }
    try:
        response = requests.post(rpc_url, json=payload, verify=True)
        if response.status_code == 200:
            print("Node is reachable, HTTP Status Code: 200")
        else:
            print(f"Node is not reachable, HTTP Status Code: {response.status_code}")
    except SSLError as e:
        print(f"TLS/SSL error: {str(e)}")
    except ConnectionError as e:
        print(f"Connection failed: {str(e)}")
    except Timeout as e:
        print(f"Request timed out: {str(e)}")


def test_functionality(rpc_url):
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1
    }

    try:
        response = requests.post(rpc_url, json=payload, verify=True)
        response_data = response.json()
        print("RPC request successful, Response Data:", response_data)
    except SSLError as e:
        print(f"TLS/SSL error: {str(e)}")
    except ConnectionError as e:
        print(f"RPC request failed, Connection error: {str(e)}")
    except Timeout as e:
        print(f"RPC request timed out: {str(e)}")
    except ValueError as e:
        print(f"RPC response parse error: {str(e)}")


def test_chain_id(rpc_url, chain_id):
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "id": chain_id,
    }

    try:
        response = requests.post(rpc_url, json=payload, verify=True)
        response_data = response.json()
        print("RPC request successful, Response Data:", response_data)
    except SSLError as e:
        print(f"TLS/SSL error: {str(e)}")
    except ConnectionError as e:
        print(f"RPC request failed, Connection error: {str(e)}")
    except Timeout as e:
        print(f"RPC request timed out: {str(e)}")
    except ValueError as e:
        print(f"RPC response parse error: {str(e)}")


if __name__ == '__main__':
    print("Testing Mainnet RPC")
    test_connectivity(MAINNET_RPC_URL)
    test_functionality(MAINNET_RPC_URL)
    test_chain_id(MAINNET_RPC_URL, MAINNET_CHAIN_ID)

    print("Testing Testnet RPC")
    test_connectivity(TESTNET_RPC_URL)
    test_functionality(TESTNET_RPC_URL)
    test_chain_id(TESTNET_RPC_URL, TESTNET_CHAIN_ID)

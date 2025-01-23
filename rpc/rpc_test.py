#!/usr/bin/python3

import requests
import json


MAINNET_RPC_URL = "https://mainnetrpc.num.network"
MAINNET_CHAIN_ID = 10507
TESTNET_RPC_URL = "https://testnetrpc.num.network"
TESTNET_CHAIN_ID = 10508


def test_connectivity(rpc_url):
    try:
        response = requests.get(rpc_url)
        if response.status_code == 200:
            print("Node is reachable, HTTP Status Code: 200")
        else:
            print(f"Node is not reachable, HTTP Status Code: {response.status_code}")
    except Exception as e:
        print(f"Connection failed, Error: {str(e)}")


def test_functionality(rpc_url):
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1
    }

    try:
        response = requests.post(rpc_url, json=payload)
        response_data = response.json()
        print("RPC request successful, Response Data:", response_data)
    except Exception as e:
        print(f"RPC request failed, Error: {str(e)}")


def test_chain_id(rpc_url, chain_id):
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "id": chain_id,
    }

    try:
        response = requests.post(rpc_url, json=payload)
        response_data = response.json()
        print("RPC request successful, Response Data:", response_data)
    except Exception as e:
        print(f"RPC request failed, Error: {str(e)}")


if __name__ == '__main__':
    print("Testing Mainnet RPC")
    test_connectivity(MAINNET_RPC_URL)
    test_functionality(MAINNET_RPC_URL)
    test_chain_id(MAINNET_RPC_URL, MAINNET_CHAIN_ID)

    print("Testing Testnet RPC")
    test_connectivity(TESTNET_RPC_URL)
    test_functionality(TESTNET_RPC_URL)
    test_chain_id(TESTNET_RPC_URL, TESTNET_CHAIN_ID)

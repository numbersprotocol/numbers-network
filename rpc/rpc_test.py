#!/usr/bin/python3

import pytest
import requests


MAINNET_RPC_URL = "https://mainnetrpc.num.network"
MAINNET_CHAIN_ID = 10507
TESTNET_RPC_URL = "https://testnetrpc.num.network"
TESTNET_CHAIN_ID = 10508


def test_mainnet_connectivity():
    response = requests.get(MAINNET_RPC_URL)
    assert response.status_code == 200, (
        f"Mainnet node not reachable, HTTP Status Code: {response.status_code}"
    )


def test_testnet_connectivity():
    response = requests.get(TESTNET_RPC_URL)
    assert response.status_code == 200, (
        f"Testnet node not reachable, HTTP Status Code: {response.status_code}"
    )


def test_mainnet_functionality():
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1,
    }
    response = requests.post(MAINNET_RPC_URL, json=payload)
    response_data = response.json()
    assert "result" in response_data, f"Unexpected response: {response_data}"


def test_testnet_functionality():
    payload = {
        "jsonrpc": "2.0",
        "method": "web3_clientVersion",
        "params": [],
        "id": 1,
    }
    response = requests.post(TESTNET_RPC_URL, json=payload)
    response_data = response.json()
    assert "result" in response_data, f"Unexpected response: {response_data}"


def test_mainnet_chain_id():
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "params": [],
        "id": 1,
    }
    response = requests.post(MAINNET_RPC_URL, json=payload)
    response_data = response.json()
    assert "result" in response_data, f"Unexpected response: {response_data}"
    assert int(response_data["result"], 16) == MAINNET_CHAIN_ID, (
        f"Expected chain ID {MAINNET_CHAIN_ID}, got {response_data['result']}"
    )


def test_testnet_chain_id():
    payload = {
        "jsonrpc": "2.0",
        "method": "eth_chainId",
        "params": [],
        "id": 1,
    }
    response = requests.post(TESTNET_RPC_URL, json=payload)
    response_data = response.json()
    assert "result" in response_data, f"Unexpected response: {response_data}"
    assert int(response_data["result"], 16) == TESTNET_CHAIN_ID, (
        f"Expected chain ID {TESTNET_CHAIN_ID}, got {response_data['result']}"
    )

#!/usr/bin/python3

import pytest
import requests


MAINNET_RPC_URL = "https://mainnetrpc.num.network"
MAINNET_CHAIN_ID = 10507
TESTNET_RPC_URL = "https://testnetrpc.num.network"
TESTNET_CHAIN_ID = 10508


def _rpc_post(rpc_url, payload):
    response = requests.post(rpc_url, json=payload, timeout=10)
    response.raise_for_status()
    return response.json()


# --- Mainnet tests ---

def test_mainnet_connectivity():
    response = requests.get(MAINNET_RPC_URL, timeout=10)
    assert response.status_code == 200, (
        f"Mainnet node not reachable, HTTP status: {response.status_code}"
    )


def test_mainnet_client_version():
    payload = {"jsonrpc": "2.0", "method": "web3_clientVersion", "params": [], "id": 1}
    data = _rpc_post(MAINNET_RPC_URL, payload)
    assert "result" in data, f"Missing 'result' in response: {data}"
    assert data["result"], "web3_clientVersion returned empty result"


def test_mainnet_chain_id():
    payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
    data = _rpc_post(MAINNET_RPC_URL, payload)
    assert "result" in data, f"Missing 'result' in response: {data}"
    assert int(data["result"], 16) == MAINNET_CHAIN_ID, (
        f"Expected chain ID {MAINNET_CHAIN_ID}, got {int(data['result'], 16)}"
    )


# --- Testnet tests ---

def test_testnet_connectivity():
    response = requests.get(TESTNET_RPC_URL, timeout=10)
    assert response.status_code == 200, (
        f"Testnet node not reachable, HTTP status: {response.status_code}"
    )


def test_testnet_client_version():
    payload = {"jsonrpc": "2.0", "method": "web3_clientVersion", "params": [], "id": 1}
    data = _rpc_post(TESTNET_RPC_URL, payload)
    assert "result" in data, f"Missing 'result' in response: {data}"
    assert data["result"], "web3_clientVersion returned empty result"


def test_testnet_chain_id():
    payload = {"jsonrpc": "2.0", "method": "eth_chainId", "params": [], "id": 1}
    data = _rpc_post(TESTNET_RPC_URL, payload)
    assert "result" in data, f"Missing 'result' in response: {data}"
    assert int(data["result"], 16) == TESTNET_CHAIN_ID, (
        f"Expected chain ID {TESTNET_CHAIN_ID}, got {int(data['result'], 16)}"
    )


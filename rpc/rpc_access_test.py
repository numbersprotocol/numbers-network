#!/usr/bin/python3

import requests
import json


RPC_URL = "https://mainnetrpc.num.network"


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
        print(f"RPC 請求失敗，錯誤信息：{str(e)}")
        print(f"RPC request failed, Error: {str(e)}")


if __name__ == '__main__':
    test_connectivity(RPC_URL)
    test_functionality(RPC_URL)


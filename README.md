# Numbers Network

Numbers Network is dedicated to preserving digital media provenance and related applications. Numbers Network is EVM-compatible, and developers familiar with Ethereum ecosystem can run their applications easily.

- [Numbers Network](#numbers-network)
  - [Mainnet: Jade (玉)](#mainnet-jade-玉)
  - [Testnet: Snow (雪)](#testnet-snow-雪)
- [Avalanche Subnets](#avalanche-subnets)
  - [Concepts](#concepts)
  - [Launch Node (avalanchego)](#launch-node-avalanchego)
  - [Create a Subnet](#create-a-subnet)
  - [Add Validator to Subnet](#add-validator-to-subnet)
  - [Renew Validator](#renew-validator)
    - [BLS Public Key and BLS Signature](#bls-public-key-and-bls-signature)
  - [RPC](#rpc)
    - [Set RPC](#set-rpc)
    - [Test RPC](#test-rpc)
  - [Upgrade Node (avalanchego)](#upgrade-node-avalanchego)
  - [Update subnet-evm](#update-subnet-evm)
  - [Updating Utilities](#updating-utilities)
  - [Network Upgrades: Enable/Disable Precompiles](#network-upgrades-enabledisable-precompiles)
  - [Customize Subnet and EVM](#customize-subnet-and-evm)
  - [Precompile: Minting Native Coins](#precompile-minting-native-coins)
    - [Check Minting Amount](#check-minting-amount)
  - [Precompile: Configuring dynamic fees](#precompile-configuring-dynamic-fees)
  - [Precompile: Restricting Smart Contract Deployers](#precompile-restricting-smart-contract-deployers)
  - [Interoperability](#interoperability)
  - [Admin](#admin)
    - [Confirm Updated Node Is Working](#confirm-updated-node-is-working)
    - [Confirm Node Is Working](#confirm-node-is-working)
- [HTTPS RPC Provider](#https-rpc-provider)
- [Websocket RPC Provider](#websocket-rpc-provider)
- [Self-Hosted Faucet](#self-hosted-faucet)
- [Wrapped NUM](#wrapped-num)
- [Bridge](#bridge)
- [Archieve Node](#archieve-node)

## Mainnet: Jade (玉)

Add Network to MetaMask, [one-click by Chainlist](https://chainlist.org/chain/10507)

1. Network Name: Numbers Jade
2. New RPC URL: https://mainnetrpc.num.network
3. Chain ID: 10507
4. Currency Symbol: NUM
5. Block Explorer URL: https://mainnet.num.network
6. Websocket RPC URL: wss://mainnetrpc.num.network/ws
7. Environment
    1. avalanchego: v1.13.0
    2. subnet-evm: v0.7.3
    3. Subnet ID: `2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ`
    4. Blockchain ID: `2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE`
    5. Chain Name: numbersevm
    6. VM ID: `qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx`
    7. VM Genesis: genesis.json
    8. Primary P-Chain Address: `P-avax142ue2exu7qxuawxe34ww8t623lv82tu2vt573g`

## Testnet: Snow (雪)

Add Network to MetaMask, [one-click by Chainlist](https://chainlist.org/chain/10508)

1. Network Name: Numbers Snow
2. New RPC URL: https://testnetrpc.num.network
3. Chain ID: 10508
4. Currency Symbol: NUM
5. Block Explorer URL: https://testnet.num.network
6. Websocket RPC URL: wss://testnetrpc.num.network/ws
7. Environment
    1. avalanchego: v1.13.0-fuji
    2. subnet-evm: v0.7.2
    3. Subnet ID: `81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe`
    4. Blockchain ID: `2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ`
    5. Chain Name: captevm
    6. VM ID: `kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT`
    7. VM Genesis: genesis-nativecoin-feemgr-feerecv.json
    8. Primary P-Chain Address: `P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk`

# Avalanche Subnets

## Concepts

1. Avalanche's high-level components: `Avalanche -> Subnets -> Chains -> VMs`
2. Every subnet / chain / vm has a unique ID.
3. Blackhole: `0x0100000000000000000000000000000000000000`, it is unchangeable.

## Launch Node (avalanchego)

Check the [official doc](https://docs.avax.network/nodes/build/run-avalanche-node-manually) for launching a node (including AWS/GCP).

You can set optional custom configs by the `--chain-config-dir` parameter, and the default directory path is `$HOME/.avalanchego/configs/chains/`.

References
1. [Avalanchego Config and Flags](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#--chain-config-dir-string)
1. [Chain Configs](https://docs.avax.network/nodes/maintain/chain-config-flags)
1. [Subnet Chain Configs](https://docs.avax.network/subnets/customize-a-subnet#chain-configs)

## Create a Subnet

Create subnet by `subnet-cli`.
1. `subnet-cli` uses the key specified in file `$PWD/.subnet-cli.pk` on the P-Chain to pay for the transaction fee.
1. `subnet-cli` uses Fuji by default. To use mainnet, add `--public-uri https://api.avax.network` ([details](https://docs.avax.network/subnets/subnet-cli#network-selection)).
1. [Avalanche transaction fee](https://docs.avax.network/quickstart/transaction-fees) lists the subnet action fees.

<details>
<summary>Command and result</summary>

```sh
ubuntu@ip-172-31-9-106:~/bafu$ ./wizard.sh                                                                                                         
2022-07-11T12:29:58.820Z        info    client/client.go:85     fetching X-Chain id             
2022-07-11T12:29:58.868Z        info    client/client.go:91     fetched X-Chain id      {"id": "2JVSBoinj9C2J33VntvzYtVJNZdN2NKiwwKjcumHUWEb5DbBrm"
}                                                                                                                                                  
2022-07-11T12:29:58.868Z        info    client/client.go:100    fetching AVAX asset id  {"uri": "https://api.avax-test.network"}
2022-07-11T12:29:58.886Z        info    client/client.go:109    fetched AVAX asset id   {"id": "U8iRqJoiJm8xZHAacmvYyZVwqQx6uDNtQeP3CQ6fcgQk3JqnK"}
2022-07-11T12:29:58.886Z        info    client/client.go:111    fetching network information
2022-07-11T12:29:58.905Z        info    client/client.go:120    fetched network information     {"networkId": 5, "networkName": "fuji"}            
                                                                                                                                                   
8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF is already a validator on 11111111111111111111111111111111LpoYY                                                  
                                                                                                                                                   
Ready to run wizard, should we continue?
*--------------------------*---------------------------------------------------*
| P-CHAIN ADDRESS          | P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk     |
*--------------------------*---------------------------------------------------*
| P-CHAIN BALANCE          | 0.7980000 $AVAX                                   |
*--------------------------*---------------------------------------------------*
| TX FEE                   | 0.201 $AVAX                                       |
*--------------------------*---------------------------------------------------*
| REQUIRED BALANCE         | 0.201 $AVAX                                       |
*--------------------------*---------------------------------------------------*
| URI                      | https://api.avax-test.network                     |
*--------------------------*---------------------------------------------------*
| NETWORK NAME             | fuji                                              |
*--------------------------*---------------------------------------------------*
| NEW SUBNET VALIDATORS    | [8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF]               |
*--------------------------*---------------------------------------------------*
| SUBNET VALIDATION WEIGHT | 1,000                                             |
*--------------------------*---------------------------------------------------*
| CHAIN NAME               | captevm                                           |
*--------------------------*---------------------------------------------------*
| VM ID                    | kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT |
*--------------------------*---------------------------------------------------*
| VM GENESIS PATH          | genesis.json                                      |
*--------------------------*---------------------------------------------------*
✔ Yes, let's create! I agree to pay the fee!


2022-07-11T12:30:23.549Z        info    client/p.go:126 creating subnet {"dryMode": false, "assetId": "U8iRqJoiJm8xZHAacmvYyZVwqQx6uDNtQeP3CQ6fcgQk
3JqnK", "createSubnetTxFee": 100000000}
2022-07-11T12:30:23.637Z        info    platformvm/checker.go:73        polling subnet  {"subnetId": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTc
eZcGG"}
2022-07-11T12:30:23.638Z        info    platformvm/checker.go:47        polling P-Chain tx      {"txId": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDr
GMTceZcGG", "expectedStatus": "Committed"}
2022-07-11T12:30:23.638Z        info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-07-11T12:30:25.680Z        info    poll/poll.go:66 poll confirmed  {"took": "2.042000706s"}
2022-07-11T12:30:25.680Z        info    platformvm/checker.go:87        finding subnets {"subnetId": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTc
eZcGG"}
2022-07-11T12:30:25.681Z        info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-07-11T12:30:25.731Z        info    poll/poll.go:66 poll confirmed  {"took": "50.443532ms"}
created subnet "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG" (took 2.092444238s)



Now, time for some config changes on your node(s).
Set --whitelisted-subnets=2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG and move the compiled VM kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdD
YuaT to <build-dir>/plugins/kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT.
When you're finished, restart your node.
✔ Yes, let's continue! I've updated --whitelisted-subnets, built my VM, and restarted my node(s)!


2022-07-11T12:31:13.342Z        info    client/p.go:294 adding subnet validator {"subnetId": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG", 
"txFee": 1000000, "start": "2022-07-11T12:31:43.251Z", "end": "2022-08-01T11:08:55.000Z", "weight": 1000}
2022-07-11T12:31:13.486Z        info    platformvm/checker.go:47        polling P-Chain tx      {"txId": "2qdbUCiUtN6MYFyJwq8MW5WDyCjVM9hrneSTbkWAB
LpTAuUf1e", "expectedStatus": "Committed"}
2022-07-11T12:31:13.486Z        info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-07-11T12:31:14.527Z        info    poll/poll.go:66 poll confirmed  {"took": "1.04094826s"}
added 8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF to subnet 2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG validator set (took 1.04094826s)

waiting for validator 8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF to start validating 2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG...(could take a few 
minutes)


2022-07-11T12:34:15.134Z        info    client/p.go:491 creating blockchain     {"subnetId": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG", 
"chainName": "captevm", "vmId": "kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT", "createBlockchainTxFee": 100000000}
created blockchain "29YUizsFS9pFPvYjsSKB23M2QAooU1yCE2dfSw6pBhpL46SA18" (took 112.952603ms)

*-------------------*----------------------------------------------------*
| P-CHAIN ADDRESS   | P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk      |
*-------------------*----------------------------------------------------*
| P-CHAIN BALANCE   | 0.6970000 $AVAX                                    |
*-------------------*----------------------------------------------------*
| URI               | https://api.avax-test.network                      |
*-------------------*----------------------------------------------------*
| NETWORK NAME      | fuji                                               |
*-------------------*----------------------------------------------------*
| SUBNET VALIDATORS | [8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF]                |
*-------------------*----------------------------------------------------*
| SUBNET ID         | 2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG |
*-------------------*----------------------------------------------------*
| BLOCKCHAIN ID     | 29YUizsFS9pFPvYjsSKB23M2QAooU1yCE2dfSw6pBhpL46SA18 |
*-------------------*----------------------------------------------------*
| CHAIN NAME        | captevm                                            |
*-------------------*----------------------------------------------------*
| VM ID             | kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT  |
*-------------------*----------------------------------------------------*
| VM GENESIS PATH   | genesis.json                                       |
*-------------------*----------------------------------------------------*
```
</details>

Check blockchain information by `platform.getBlockchains`:

```
{
  "id": "29YUizsFS9pFPvYjsSKB23M2QAooU1yCE2dfSw6pBhpL46SA18",
  "name": "captevm",
  "subnetID": "2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG",
  "vmID": "kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT"
}
```

Add validator to subnet

<details>
<summary>Command and result</summary>

```sh
ubuntu@ip-172-31-9-106:~/bafu$ ./subnet-cli-add-subnet-validator.sh 
2022-07-11T11:14:14.608Z        info    client/client.go:85     fetching X-Chain id
2022-07-11T11:14:14.843Z        info    client/client.go:91     fetched X-Chain id      {"id": "2JVSBoinj9C2J33VntvzYtVJNZdN2NKiwwKjcumHUWEb5DbBrm"}
2022-07-11T11:14:14.843Z        info    client/client.go:100    fetching AVAX asset id  {"uri": "https://api.avax-test.network"}
2022-07-11T11:14:14.862Z        info    client/client.go:109    fetched AVAX asset id   {"id": "U8iRqJoiJm8xZHAacmvYyZVwqQx6uDNtQeP3CQ6fcgQk3JqnK"}2022-07-11T11:14:14.862Z        info    client/client.go:111    fetching network information
2022-07-11T11:14:14.878Z        info    client/client.go:120    fetched network information     {"networkId": 5, "networkName": "fuji"}

Ready to add subnet validator, should we continue?
*------------------*---------------------------------------------------*
| P-CHAIN ADDRESS  | P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk     |
*------------------*---------------------------------------------------*
| P-CHAIN BALANCE  | 0.7990000 $AVAX                                   |
*------------------*---------------------------------------------------*
| TX FEE           | 0.001 $AVAX                                       |
*------------------*---------------------------------------------------*
| REQUIRED BALANCE | 0.001 $AVAX                                       |
*------------------*---------------------------------------------------*
| URI              | https://api.avax-test.network                     |
*------------------*---------------------------------------------------*
| NETWORK NAME     | fuji                                              |
*------------------*---------------------------------------------------*
| NODE IDs         | [8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF]               |
*------------------*---------------------------------------------------*
| SUBNET ID        | GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL |
*------------------*---------------------------------------------------*
| VALIDATE WEIGHT  | 1,000                                             |
*------------------*---------------------------------------------------*
✔ Yes, let's create! I agree to pay the fee!



2022-07-11T11:14:32.624Z        info    client/p.go:294 adding subnet validator {"subnetId": "GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL", "txFee": 1000000, "start": "2022-07-11T11:15:02.564Z", "end": "2022-08-01T11:08:55.000Z", "weight": 1000}
2022-07-11T11:14:32.741Z        info    platformvm/checker.go:47        polling P-Chain tx      {"txId": "2Hptsj3d3YxF1riZTG9aFHFrjqNMWfpGmPFyHevSSaUDsob4uy", "expectedStatus": "Committed"}
2022-07-11T11:14:32.742Z        info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-07-11T11:14:34.782Z        info    poll/poll.go:66 poll confirmed  {"took": "2.040226592s"}
added 8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF to subnet GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL validator set (took 2.040226592s)

waiting for validator 8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF to start validating GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL...(could take a few minutes)
*------------------*---------------------------------------------------*
| P-CHAIN ADDRESS  | P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk     |
*------------------*---------------------------------------------------*
| P-CHAIN BALANCE  | 0.7980000 $AVAX                                   |
*------------------*---------------------------------------------------*
| URI              | https://api.avax-test.network                     |
*------------------*---------------------------------------------------*
| NETWORK NAME     | fuji                                              |
*------------------*---------------------------------------------------*
| NODE IDs         | [8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF]               |
*------------------*---------------------------------------------------*
| SUBNET ID        | GBEwakER8HzKT7U2mWuVafxTTAMYVQnDXeT92NcCVt4gwfLUL |
*------------------*---------------------------------------------------*
| VALIDATE START   | 2022-07-11T11:15:02Z                              |
*------------------*---------------------------------------------------*
| VALIDATE END     | 2022-08-01T11:08:55Z                              |
*------------------*---------------------------------------------------*
| VALIDATE WEIGHT  | 1,000                                             |
*------------------*---------------------------------------------------*
```
</details>

Launch validator. When running `avalanchego`, add

* `-—http-host=0.0.0.0`: Make MetaMask can access the RPC URL
* `--http-allowed-hosts="*"`: Allow traffic from the RPC node (since v1.10.3)

```sh
./avalanchego \
    --track-subnets=81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe\
    --network-id=fuji \
    --http-host=0.0.0.0 \
    --http-allowed-hosts="*" \
    --public-ip=<node-public-ip>
```

## Add Validator to Subnet

High-level concepts

1. Make a node as validator
    1. Visit [wallet.avax.network](https://wallet.avax.network/wallet/earn)
    1. Follow the steps in [this official doc](https://docs.avax.network/nodes/validate/add-a-validator#add-as-a-validator).
        1. Ensure there is sufficient balance on P-Chain.
1. Add the validator to the subnet
    1. Ues subnet admin to run `subnet-cli`. Find the Subnet admin in the Subnets section below.
        1. In general, you will run `subnet-cli` on your notebook instead of validator nodes.
        1. You can use [`avalanchego-api-scripts/subnet-cli/install-subnet-cli-testnet.sh`](https://github.com/numbersprotocol/avalanchego-api-scripts/blob/main/subnet-cli/subnet-cli-add-subnet-validator-testnet.sh) to install.
    1. Run the command

        ```shell
        # testnet
        subnet-cli add subnet-validator \
            --node-ids="NodeID-7TwAjiRpTbNcqUx6F9EoyXRBLAfeoQXRq" \
            --subnet-id="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"

        # mainnet
        subnet-cli add subnet-validator \
            --node-ids="NodeID-BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx" \
            --subnet-id="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ" \
            --public-uri "https://api.avax.network"
        ```

    1. `subnet-cli` will find private key from `$PWD/.subnet-cli.pk` by default.
    1. The wallet needs to have 0.001 AVAX at least on P-Chain (Fuji).

If you see `Error: validator not found` when adding a validator to subnet and confirmed that you've re-staked successfully, you can check if the node is running as P-Chain validator by checking the node's explorer page: `https://subnets-test.avax.network/validators/NodeID-<node-id>`. After re-staking, P-Chain needs minutes to update the validator status.

## Renew Validator

If the validator's staking duration is expired, the staking amount and rewards will be sent to the staking wallet on P-Chain automatically. You can follow the same steps above to add it as a validator again.

Before validation staking expires, any wallet can not stake to a validator again. If you try to do so on wallet.avax.network, you will get the error message

> couldn't issue tx: attempted to issue duplicate validation for NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p

Validator version distributions: [mainnet](https://explorer-xp.avax.network/validators), [testnet](https://explorer-xp.avax-test.network/validators)

[Renew Numbers Validators](https://app.asana.com/0/1202305127727547/1202919355642524/f) (internal task)

### BLS Public Key and BLS Signature

If you're asked to provide BLS Public Key and BLS Signature, you can get them by running the following command on the validator node:

```sh
curl -X POST --data '{
    "jsonrpc":"2.0",
    "id"     :1,
    "method" :"info.getNodeID"
}' -H 'content-type:application/json;' 127.0.0.1:9650/ext/info
```

It should return something like this.

```sh
{
  "jsonrpc": "2.0",
  "result": {
    "nodeID": "NodeID-5mb46qkSBj81k9g9e4VFjGGSbaaSLFRzD",
    "nodePOP": {
      "publicKey": "0x8f95423f7142d00a48e1014a3de8d28907d420dc33b3052a6dee03a3f2941a393c2351e354704ca66a3fc29870282e15",
      "proofOfPossession": "0x86a3ab4c45cfe31cae34c1d06f212434ac71b1be6cfe046c80c162e057614a94a5bc9f1ded1a7029deb0ba4ca7c9b71411e293438691be79c2dbf19d1ca7c3eadb9c756246fc5de5b7b89511c7d7302ae051d9e03d7991138299b5ed6a570a98"
    }
  },
  "id": 1
}
```

The publicKey is your BLS Public Key, and proofOfPossession is your BLS Signature. Avalanche uses your public key as the signing message ([source 1](https://docs.avax.network/nodes/validate/add-a-validator#validation-period), [source 2](https://docs.avax.network/nodes/maintain/node-backup-and-restore#nodeid)).

## RPC

[MetaMask RPC rule](https://docs.avax.network/subnets/deploy-a-smart-contract-on-your-evm#step-1-setting-up-metamask): `http://NodeIPAddress:9650/ext/bc/BlockchainID/rpc`

### Set RPC

Use Nginx as RPC load balancer.

```sh
$ vim /etc/nginx/sites-available/default
```

### Test RPC

Test the RPC connectivity and functionality:

```sh
$ python3 rpc/rpc_test.py
```

Testing result:

```sh
Testing Mainnet RPC
Node is reachable, HTTP Status Code: 200
RPC request successful, Response Data: {'jsonrpc': '2.0', 'id': 1, 'result': 'v0.7.0'}
RPC request successful, Response Data: {'jsonrpc': '2.0', 'id': 10507, 'result': '0x290b'}
Testing Testnet RPC
Node is reachable, HTTP Status Code: 200
RPC request successful, Response Data: {'jsonrpc': '2.0', 'id': 1, 'result': 'v0.6.12'}
RPC request successful, Response Data: {'jsonrpc': '2.0', 'id': 10508, 'result': '0x290c'}
```

## Upgrade Node (avalanchego)

[Upgrade Your AvalancheGo Node](https://docs.avax.network/nodes/maintain/upgrade-your-avalanchego-node)

1. Backup node

    ```sh
    cd
    cp ~/.avalanchego/staking/staker.crt .
    cp ~/.avalanchego/staking/staker.key .
    ```

1. Download pre-build `avalanchego` and `subnet-evm`
1. Copy `subnet-evm` binary to `avalanchego/plugins/<vmid>`
1. Stop the running `avalanchego`
1. Start the new `avalanchego`

Notes

1. When upgrading node, you need to upgrade EVM and plugins as well.

    > [jpop32 — 05/12/2021](https://discord.com/channels/578992315641626624/757576823570825316/841775940706762762)
    > Plugin is the part of the installation. And it has to be upgraded along with the main executable, yes.

Since `avalanchego v1.9.6`, there are two breaking changes

1. There is no `avalanchego/plugins/evm` (Subnet EVM) because it has been merged into `avalanchego` directly.
1. The default plugins directory is `~/.avalanchego/plugins/`

```
$ tree avalanchego-v1.9.6
avalanchego-v1.9.6
└── avalanchego

$ tree ~/.avalanchego/plugins/
/home/<account>/.avalanchego/plugins/
└── kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT
```

## Update subnet-evm

1. Download the latest pre-built binary on [subnet-evm GitHub](https://github.com/ava-labs/subnet-evm).
1. Copy the subnet-evm binary to `~/.avalanchego/plugins/<vmID>`
1. Restart node (`avalanchego`)

## Updating Utilities

See `chains/update-validator-{mainnet,testnet}.sh`.

## Network Upgrades: Enable/Disable Precompiles

1. https://docs.avax.network/subnets/customize-a-subnet#network-upgrades-enabledisable-precompiles
1. https://github.com/ava-labs/subnet-evm/issues/177#issuecomment-1214296935

## Customize Subnet and EVM

> Each blockchain has some genesis state when it’s created.
> Each Virtual Machine defines the format and semantics of its genesis data.

Config directory structure

```sh
$ tree ~/.avalanchego/configs/
/home/ubuntu/.avalanchego/configs/
├── chains
│   └── 29YUizsFS9pFPvYjsSKB23M2QAooU1yCE2dfSw6pBhpL46SA18
│       └── config.json
└── subnets
    └── 2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG.json
```

Tips
1. After updating `config.json`, `avalanchego` needs to be restarted.
2. If you add fee recipient, the fee recipient will get 100% gas fee.

References
1. https://docs.avax.network/subnets/customize-a-subnet
2. https://github.com/ava-labs/subnet-evm/tree/master/contract-examples

## Precompile: Minting Native Coins

```
> contract = await ethers.getContractAt("NativeMinterInterface", "0x0200000000000000000000000000000000000001")

> [admin] = await ethers.getSigners()

> await admin.getBalance()
BigNumber { value: "99999999999845284000000300" }

> r = await contract.mintNativeCoin(admin.address, 100)

> await admin.getBalance()
BigNumber { value: "99999999999793712000000400" }
```

Check the [official doc](https://docs.avax.network/subnets/customize-a-subnet#minting-native-coins) for the details.

### Check Minting Amount

[Example Tx](https://mainnet.num.network/transaction/0xc20e2e32396b3555140f4cc2dfacf50cc334b6d49ded042c5a137ab31442b317)

data

```
0x4f5aaaba0000000000000000000000008cba0477d89394e6d8ad658e11d52113a2da4ab20000000000000000000000000000000000000000001acff4350c4a1576280000
```

decode

```
Signature (Method ID): 0x4f5aaaba
[0]: 0000000000000000000000008cba0477d89394e6d8ad658e11d52113a2da4ab2
[1]: 0000000000000000000000000000000000000000001acff4350c4a1576280000
```

[decode [1]](https://www.binaryhexconverter.com/hex-to-decimal-converter), the result is `32414106000000000000000000` (32,414,106 in Wei).

## Precompile: Configuring dynamic fees

```
> fm = await ethers.getContractAt("IFeeManager", "0x0200000000000000000000000000000000000003")

> await fm.getFeeConfig()
[
  BigNumber { value: "20000000" },
  BigNumber { value: "2" },
  BigNumber { value: "1000000000" },
  BigNumber { value: "100000000" },
  BigNumber { value: "48" },
  BigNumber { value: "0" },
  BigNumber { value: "10000000" },
  BigNumber { value: "500000" },
  gasLimit: BigNumber { value: "20000000" },
  targetBlockRate: BigNumber { value: "2" },
  minBaseFee: BigNumber { value: "1000000000" },
  targetGas: BigNumber { value: "100000000" },
  baseFeeChangeDenominator: BigNumber { value: "48" },
  minBlockGasCost: BigNumber { value: "0" },
  maxBlockGasCost: BigNumber { value: "10000000" },
  blockGasCostStep: BigNumber { value: "500000" }
]

> await fm.setFeeConfig(20000000, 2, 1000000000, 100000000, 48, 0, 10000000, 500000)

> await fm.getFeeConfig()
[
  BigNumber { value: "20000000" },
  BigNumber { value: "2" },
  BigNumber { value: "2000000000" },
  BigNumber { value: "100000000" },
  BigNumber { value: "48" },
  BigNumber { value: "0" },
  BigNumber { value: "10000000" },
  BigNumber { value: "500000" },
  gasLimit: BigNumber { value: "20000000" },
  targetBlockRate: BigNumber { value: "2" },
  minBaseFee: BigNumber { value: "2000000000" },
  targetGas: BigNumber { value: "100000000" },
  baseFeeChangeDenominator: BigNumber { value: "48" },
  minBlockGasCost: BigNumber { value: "0" },
  maxBlockGasCost: BigNumber { value: "10000000" },
  blockGasCostStep: BigNumber { value: "500000" }
]
```

Check the [official doc](https://docs.avax.network/subnets/customize-a-subnet#configuring-dynamic-fees) for the details.

## Precompile: Restricting Smart Contract Deployers

```
> contract = await ethers.getContractAt("IAllowList", "0x0200000000000000000000000000000000000000")

> [admin, test] = await ethers.getSigners()

# 0: None, 1: Enabled, 2: Admin
> await contract.readAllowList(admin.address)
BigNumber { value: "2" }

> await contract.readAllowList(test.address)
BigNumber { value: "0" }

> await contract.setEnabled(test.address)
{
  hash: '0xd117e990e85c2428a620f9bd834b0597db1648f3d2fa5899d929fd1701d46e01',
  type: 0,
  accessList: null,
  blockHash: '0xf6063f0c5e86ab4efaf970e901ca3f5be3335ec61ab8f50fc075a6915f5e19e5',
  blockNumber: 5,
  transactionIndex: 0,
  confirmations: 1,
  from: '0x8Cba0477d89394E6d8aD658E11d52113A2DA4Ab2',
  gasPrice: BigNumber { value: "100000000000" },
  gasLimit: BigNumber { value: "41432" },
  to: '0x0200000000000000000000000000000000000000',
  value: BigNumber { value: "0" },
  nonce: 2,
  data: '0x0aaf704300000000000000000000000063b7076fc0a914af543c2e5c201df6c29fcc18c5',
  r: '0x01e0c663a55757e12237f001811cab7a610c3ebfeba99ac9f0e29cbe4f4bd5ed',
  s: '0x38b126e31bb8ee608e45554956c9a6eefb091961755283f9dff69964c2512f41',
  v: 21049,
  creates: null,
  chainId: 10507,
  wait: [Function (anonymous)]
}

> await contract.readAllowList(test.address)
BigNumber { value: "1" }
```

Check the [official doc](https://docs.avax.network/subnets/customize-a-subnet#restricting-smart-contract-deployers) for the details.

## Interoperability

* [Overview](https://ava-labs-preview-4bd33b78-6a2a-400d-a6ba-4df588ac1831.docs.buildwithfern.com/portal/interoperability/overview)
* [CCTP](https://developers.circle.com/cctp/cctp-supported-blockchains)

## Admin

[avalanchego-api-scripts](https://github.com/numbersprotocol/avalanchego-api-scripts) is the admin toolkit.

### Confirm Updated Node Is Working

Node will show "consensus starting" for both C-Chain and P-Chain:

```
[10-02|06:32:32.114] INFO <C Chain> snowman/transitive.go:401 consensus starting {"lastAcceptedBlock": "2L56FDEYAemMKTJ2uD1MnGpC1pC2WBgeNtwyjh6AhgTffvCWR2"}
[10-02|06:32:32.117] INFO <P Chain> snowman/transitive.go:401 consensus starting {"lastAcceptedBlock": "22egidV1exdWT8ckaAf8dv9YiWAs2ESmY2NmtJUwNqBGCyNef2"}
[10-02|06:32:41.919] INFO <X Chain> avalanche/transitive.go:346 consensus starting {"lenFrontier": 1}
```

Now, you can check if the Node is running normally.

### Confirm Node Is Working

```
$ cd ~/avalanchego-api-scripts/api
$ watch -n 5 ./info.isBootstrapped.sh X
$ watch -n 5 ./info.isBootstrapped.sh 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ
$ watch -n 5 ./health.health.sh

# Show validators by giving the Subnet ID
$ ./platform.getCurrentValidators.sh 81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1318  100  1139  100   179  21189   3330 --:--:-- --:--:-- --:--:-- 24867
{
  "jsonrpc": "2.0",
  "result": {
    "validators": [
      {
        "txID": "QWwjVDJTX2pSYxi5oNk51VeZaZPip9jZnSVhLqipgKMRJDxFP",
        "startTime": "1662288001",
        "endTime": "1677599993",
        "stakeAmount": "1000",
        "nodeID": "NodeID-7TwAjiRpTbNcqUx6F9EoyXRBLAfeoQXRq",
        "connected": true,
        "uptime": "1.0000"
      },
      {
        "txID": "2cfHmfw29UBCjMDTRb9RwistPFekmHzEdfpNci1TLLeoMdtckZ",
        "startTime": "1662363248",
        "endTime": "1680278397",
        "stakeAmount": "1000",
        "nodeID": "NodeID-JbeonHKqomERomXgCiXr9oC9vfynkBupj",
        "connected": true,
        "uptime": "1.0000"
      },
      {
        "txID": "2PqA6BE5wiA5iE9yZeMsfaSag4pT5U1uxMMGyia1HCF6SEUNRe",
        "startTime": "1662364392",
        "endTime": "1682870344",
        "stakeAmount": "1000",
        "nodeID": "NodeID-BffXkmzM8EwrBZgpqFp9pwgE9DbDgYKG2",
        "connected": true,
        "uptime": "1.0000"
      },
      {
        "txID": "26mBFfgiFTz3eFo1QAmvMiBpfTtmgMvzPJ2eB5V6WjK2CkTcuJ",
        "startTime": "1667294891",
        "endTime": "1685548750",
        "stakeAmount": "1000",
        "nodeID": "NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW",
        "connected": true,
        "uptime": "1.0000"
      },
      {
        "txID": "kApLebvYz54fRratWmWqEttbNktbCDQMK93mDmr1rm9w64gDU",
        "startTime": "1669827497",
        "endTime": "1688140751",
        "stakeAmount": "1000",
        "nodeID": "NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p",
        "connected": true,
        "uptime": "1.0000"
      }
    ]
  },
  "id": 1
}
```

Using `info.peers` to check all the nodes and versions in a subnet. The nodes might not be validators. The node running the command will not be listed in the result. Remember to add `--public-ip=<public-ip>` when running `avalanchego`. Check public IPs are correct and uptimes are > 98.

```
$ ./info.peers.sh  | jq .
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  2027  100  1661  100   366   435k  98255 --:--:-- --:--:-- --:--:--  659k
{
  "jsonrpc": "2.0",
  "result": {
    "numPeers": "4",
    "peers": [
      ...
      {
        "ip": "<private-or-public-ip-and-port>",
        "publicIP": "private-ip-and-port",
        "nodeID": "NodeID-A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p",
        "version": "avalanche/1.9.4",
        "lastSent": "2023-01-27T17:03:56Z",
        "lastReceived": "2023-01-27T17:03:52Z",
        "observedUptime": "99",
        "observedSubnetUptimes": {
          "81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe": "99"
        },
        "trackedSubnets": [
          "81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"
        ],
        "benched": []
      }
    ]
  },
  "id": 1
}
```

# HTTPS RPC Provider

Concept: Nginx with Certbot as reverse proxy redirects RPC requests to the validators.

# Websocket RPC Provider

Concept: Nginx with Certbot as reverse proxy redirects RPC requests to the websocket endpoint of validators.

Websocket log subscription example using Python:

```sh
pip3 install websockets
```

```python
import asyncio
import json

from websockets import connect


async def get_event():
    async with connect('wss://testnetrpc.num.network/ws') as ws:
        await ws.send('{"jsonrpc":"2.0", "id": 1, "method": "eth_subscribe", "params": ["logs", {"topics": []}]}')
        subscription_response = await ws.recv()
        print(subscription_response)
        while True:
            try:
                message = await asyncio.wait_for(ws.recv(), timeout=60)
                print(json.loads(message))
            except asyncio.TimeoutError:
                pass
            except Exception as e:
                print(f'Error: {e}')
                break


if __name__ == '__main__':
    asyncio.run(get_event())

```

# Self-Hosted Faucet

https://faucet.num.network

1. Create product build.
    1. Copy `.env` to `build/` where product server.ts is there.
2. Copy `build/client/*` to `/var/www/html/faucet/`.
3. Update Nginx config.

    ```
    +upstream faucet {
    +        server localhost:8000
    +}
    ...
    -        root /var/www/html;
    +        root /var/www/html/faucet;
    ...
    +        location /api/ {
    +                proxy_pass http://faucet
    +        }
    ```

4. Run product server: `npm start`
5. Utility commands

    ```
    $ sudo service nginx configtest
    $ sudo service nginx reload
    ```
# Wrapped NUM

We completed a technical survey and verified some concepts on the testnet.

If you are interested in wrapped ERC20 token, refer to [canonical-wnum](https://github.com/numbersprotocol/canonical-wnum/).

# Bridge

To bridge native NUM to ERC20/BEP20 NUM, you can use [XY Finance](https://app.xy.finance/) ([audit report](https://docs.xy.finance/getting-started/security)).

<img src="https://user-images.githubusercontent.com/292790/208720428-ab794a2a-ab4d-406e-a51c-63e6ef01a5d4.png" width="50%">

To know more about NUM token, you can visit the [NUM token website](https://num.numbersprotocol.io/).

# Archieve Node

Archive Node provides full history of the blockchain and does not need to be a validator.

[Running an Archival Node](https://docs.avax.network/dapps/launch-your-ethereum-dapp#running-an-archival-node)
* [state sync bootstrapping has to be off](https://docs.avax.network/nodes/build/set-up-node-with-installer#running-the-script).
* [~2TB storage size for archive node](https://support.avax.network/en/articles/6158842-nodes-faq)

Make a Full Node instance to be an Archive Node instance:
1. Create an instance from full node image
1. Increase disk space to 2TB
1. Delete `~/.avalanchego/staking/*`
1. Update network config
    * mainnet: `~/.avalanchego/configs/chains/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/config.json`
    * testnet: `~/.avalanchego/configs/chains/2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/config.json`

    ```sh
    {
        "pruning-enabled": false,
        # newly added content
        "eth-apis": [
            "eth",
            "eth-filter",
            "net",
            "web3",
            "internal-eth",
            "internal-blockchain",
            "internal-transaction",
            "debug-tracer"
        ]
    }
    ```

1. Run an Archive Node by `avalanchego`

    Run an archive node for mainnet

    ```sh
    #!/bin/sh

    # Subnet IDs
    SUBNET_MAINNET="2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"

    ./avalanchego \
        --track-subnets=${SUBNET_MAINNET} \
        --http-host=0.0.0.0 \
        --public-ip=<node-public-ip> \
        --http-allowed-hosts="*"
    ```

    Run an archive node for testnet

    ```sh
    #!/bin/sh

    # Subnet IDs
    SUBNET_MAINNET="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"

    ./avalanchego \
        --track-subnets=${SUBNET_MAINNET} \
        --http-host=0.0.0.0 \
        --public-ip=<node-public-ip> \
        --http-allowed-hosts="*"
    ```

1. (optional) Test an Archive Node

    Run the commands on the Archive Node's instances for testing it's working as Archive Node.

    For mainnet

    ```sh
    $ curl http://localhost:9650/ext/bc/2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE/rpc \
         -X POST \
         -H "Content-Type: application/json" \
        --data '{"method":"debug_traceTransaction","params":["0x9a241e580d29d90d890316559d055c0df5cc7203be43b166d63c51de2218efc8"],"id":1,"jsonrpc":"2.0"}'
    ```

    For testnet

    ```sh
    $ curl http://localhost:9650/ext/bc/2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ/rpc \
         -X POST \
         -H "Content-Type: application/json" \
        --data '{"method":"debug_traceTransaction","params":["0x7d2dec6c3e7ce2a387d988a0603ce7de6d487d6aeaf6b58eabdb123161cee0a2"],"id":1,"jsonrpc":"2.0"}'
    ```

    [Discord discussion](https://discord.com/channels/578992315641626624/905684871731634196/1026850988042244247)

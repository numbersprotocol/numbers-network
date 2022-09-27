# Numbers Network

- [Numbers Network](#numbers-network)
  - [Testnet: Snow (雪)](#testnet-snow-雪)
  - [Mainnet: Jade (玉)](#mainnet-jade-玉)
- [Avalanche Subnets](#avalanche-subnets)
  - [Concepts](#concepts)
  - [Launch Node (avalanchego)](#launch-node-avalanchego)
  - [Create a Subnet](#create-a-subnet)
  - [Add Validator to Subnet](#add-validator-to-subnet)
  - [RPC](#rpc)
  - [Upgrade Node (avalanchego)](#upgrade-node-avalanchego)
  - [Update subnet-evm](#update-subnet-evm)
  - [Network Upgrades: Enable/Disable Precompiles](#network-upgrades-enabledisable-precompiles)
  - [Customize Subnet and EVM](#customize-subnet-and-evm)
  - [Precompile: Minting Native Coins](#precompile-minting-native-coins)
  - [Precompile: Configuring dynamic fees](#precompile-configuring-dynamic-fees)
  - [Admin](#admin)
    - [Confirm Node Is Working](#confirm-node-is-working)
- [HTTPS RPC Provider](#https-rpc-provider)
- [Self-Hosted Faucet](#self-hosted-faucet)
  - [Wrapped NUM](#wrapped-num)
  - [Bridge](#bridge)

## Testnet: Snow (雪)

Add Network to MetaMask

1. Network Name: Numbers Snow
2. New RPC URL: https://testnetrpc.num.network
3. Chain ID: 10508
4. Currency Symbol: NUM
5. Block Explorer URL: https://testnet.num.network

```
*-------------------------*-----------------------------------------------------------------------*
| PRIMARY P-CHAIN ADDRESS | P-fuji1lcztar3x7ra0ajen3dtw4mdhk2cyshfhu2hzgk                         |
*-------------------------*-----------------------------------------------------------------------*
| TOTAL P-CHAIN BALANCE   | 2.0910000 $AVAX                                                       |
*-------------------------*-----------------------------------------------------------------------*
| URI                     | https://api.avax-test.network                                         |
*-------------------------*-----------------------------------------------------------------------*
| NETWORK NAME            | fuji                                                                  |
*-------------------------*-----------------------------------------------------------------------*
| SUBNET VALIDATORS       | [24WK7qiKXAumya1kKEktwj2ubBbRyq5UW A2Z8m7egVLhKf1Qj14uvXadhExM5zrB7p] |
*-------------------------*-----------------------------------------------------------------------*
| SUBNET ID               | 81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe                     |
*-------------------------*-----------------------------------------------------------------------*
| BLOCKCHAIN ID           | 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ                    |
*-------------------------*-----------------------------------------------------------------------*
| CHAIN NAME              | captevm                                                               |
*-------------------------*-----------------------------------------------------------------------*
| VM ID                   | kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT                     |
*-------------------------*-----------------------------------------------------------------------*
| VM GENESIS PATH         | ../genesis/genesis-nativecoin-feemgr-feerecv.json                     |
*-------------------------*-----------------------------------------------------------------------*
```

Environment

1. avalanchego: 1.8.4
2. subnet-evm: 0.3.0

## Mainnet: Jade (玉)

Stay tuned

# Avalanche Subnets

## Concepts

1. Avalanche's high-level components: Avalanche -> Subnets -> Chains -> VMs
2. Every subnet / chain / vm has an unique ID.

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

Launch validator. When running `avalanchego`, adding `—http-host=0.0.0.0` so that MetaMask can access the RPC URL.

```
./avalanchego --whitelisted-subnets=2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG --network-id=fuji --http-host=0.0.0.0
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
    1. Run the command

        ```shell
        subnet-cli add subnet-validator \
            --node-ids="NodeID-8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF" \
            --subnet-id="2fQBahhq3F9eip8KobMgjbvBEahW3153kvAy6YPDrGMTceZcGG"
        ```

    1. `subnet-cli` will find private key from `$PWD/.subnet-cli.pk` by default.
    1. The wallet needs to have 0.001 AVAX at least on P-Chain (Fuji).

If the validator's staking duration is expired, you can follow the same steps above to add it as a validator again.

## RPC

[MetaMask RPC rule](https://docs.avax.network/subnets/deploy-a-smart-contract-on-your-evm#step-1-setting-up-metamask): `http://NodeIPAddress:9650/ext/bc/BlockchainID/rpc`

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

```
$ tree avalanchego-v1.7.14
avalanchego-v1.7.14
├── avalanchego
└── plugins
    ├── evm
    └── kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT

1 directory, 3 files

```

## Update subnet-evm

1. Download the latest pre-built binary on [subnet-evm GitHub](https://github.com/ava-labs/subnet-evm).
1. Copy the subnet-evm binary to `<avalanchego>/plugins/<vmID>`
1. Restart node (`avalanchego`)

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

## Admin

[avalanchego-api-scripts](https://github.com/numbersprotocol/avalanchego-api-scripts) is the admin toolkit.

### Confirm Node Is Working

```
$ cd ~/avalanchego-api-scripts/api
$ watch -n 5 ./info.isBootstrapped.sh X
$ watch -n 5 ./info.isBootstrapped.sh 2oo5UvYgFQikM7KBsMXFQE3RQv3xAFFc8JY2GEBNBF1tp4JaeZ
$ watch -n 5 ./health.health.sh

# Show validators by giving the Subnet ID
$ ./platform.getCurrentValidators.sh 81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe
```

# HTTPS RPC Provider

Concept: Nginx with Certbot as reverse proxy redirects RPC requests to the validators.

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
## Wrapped NUM

Refer to [canonical-wnum](https://github.com/numbersprotocol/canonical-wnum/).

## Bridge

ChainBridge

1. [chainbridge-deploy](https://github.com/ChainSafe/chainbridge-deploy) v1.0.0
    1. Generate contract deployer `cb-sol-cli`
1. [chainbridge](https://github.com/ChainSafe/chainbridge) v1.1.1
    1. Generate relayer `chainbridge`

References

1. https://docs.avax.network/subnets/deploying-cross-chain-evm-bridge
1. https://chainbridge.chainsafe.io/live-evm-bridge/#and-back-again
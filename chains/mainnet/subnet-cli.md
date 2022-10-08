Pre-conditions

1. Clone the `avalanchego-api-scripts` repository.
2. Create `.subnet-cli.pk` in `subnet-cli/`.
3. Copy numbers-network's mainnet genesis.json in `subnet-cli/`.

```
 bafu@bafu-XPS-13-7390  ~/codes/avalanchego-api-scripts/subnet-cli   main  cat subnet-cli-wizard-mainnet.sh
#!/bin/bash
#
# --node-ids: If you have multiple nodes, use comma to separate them.
#             Ex: NodeID-8CGJYaRLChC79CCRnvd7sh5eB9E9L9dVF,NodeID-24WK7qiKXAumya1kKEktwj2ubBbRyq5UW

subnet-cli wizard \
    --node-ids NodeID-BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx \
    --vm-genesis-path ./genesis.json \
    --vm-id qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx \
    --chain-name numbersevm \
    --public-uri https://api.avax.network

```

```
 bafu@bafu-XPS-13-7390  ~/codes/avalanchego-api-scripts/subnet-cli   main  ./subnet-cli-wizard-mainnet.sh
2022-10-08T22:38:59.523+0800    info    client/client.go:81     fetching X-Chain id
2022-10-08T22:38:59.771+0800    info    client/client.go:87     fetched X-Chain id      {"id": "2oYMBNV4eNHyqk2fjjV5nVQLDbtmNJzq5s3qs3Lo6ftnC6FByM"}
2022-10-08T22:38:59.771+0800    info    client/client.go:96     fetching AVAX asset id  {"uri": "https://api.avax.network"}
2022-10-08T22:38:59.830+0800    info    client/client.go:105    fetched AVAX asset id   {"id": "FvwEAhmxKfeiG8SnEvq42hc6whRyY3EFYAvebMqDNDGCgxN5Z"}
2022-10-08T22:38:59.830+0800    info    client/client.go:107    fetching network information
2022-10-08T22:38:59.885+0800    info    client/client.go:116    fetched network information     {"networkId": 1, "networkName": "mainnet"}

BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx is already a validator on 11111111111111111111111111111111LpoYY

Ready to run wizard, should we continue?
*--------------------------*---------------------------------------------------*
| PRIMARY P-CHAIN ADDRESS  | P-avax142ue2exu7qxuawxe34ww8t623lv82tu2vt573g     |
*--------------------------*---------------------------------------------------*
| TOTAL P-CHAIN BALANCE    | 8.0000000 $AVAX                                   |
*--------------------------*---------------------------------------------------*
| TX FEE                   | 2.001 $AVAX                                       |
*--------------------------*---------------------------------------------------*
| EACH STAKE AMOUNT        | 1.000 $AVAX                                       |
*--------------------------*---------------------------------------------------*
| REQUIRED BALANCE         | 3.001 $AVAX                                       |
*--------------------------*---------------------------------------------------*
| URI                      | https://api.avax.network                          |
*--------------------------*---------------------------------------------------*
| NETWORK NAME             | mainnet                                           |
*--------------------------*---------------------------------------------------*
| NEW SUBNET VALIDATORS    | [BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx]               |
*--------------------------*---------------------------------------------------*
| SUBNET VALIDATION WEIGHT | 1,000                                             |
*--------------------------*---------------------------------------------------*
| CHAIN NAME               | numbersevm                                        |
*--------------------------*---------------------------------------------------*
| VM ID                    | qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx |
*--------------------------*---------------------------------------------------*
| VM GENESIS PATH          | ./genesis.json                                    |
*--------------------------*---------------------------------------------------*
✔ Yes, let's create! I agree to pay the fee!


2022-10-08T22:39:16.819+0800    info    client/p.go:131 creating subnet {"dryMode": false, "assetId": "FvwEAhmxKfeiG8SnEvq42hc6whRyY3EFYAvebMqDNDGCgxN5Z", "createSubnetTxFee": 1000000000}
2022-10-08T22:39:17.536+0800    info    platformvm/checker.go:74        polling subnet  {"subnetId": "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"}
2022-10-08T22:39:17.538+0800    info    platformvm/checker.go:48        polling P-Chain tx      {"txId": "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ", "expectedStatus": "Committed"}
2022-10-08T22:39:17.538+0800    info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-10-08T22:39:22.844+0800    info    poll/poll.go:66 poll confirmed  {"took": "5.305796004s"}
2022-10-08T22:39:22.844+0800    info    platformvm/checker.go:88        finding subnets {"subnetId": "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ"}
2022-10-08T22:39:22.844+0800    info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-10-08T22:39:24.281+0800    info    poll/poll.go:66 poll confirmed  {"took": "1.437609493s"}
created subnet "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ" (took 6.743405497s)



Now, time for some config changes on your node(s).
Set --whitelisted-subnets=2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ and move the compiled VM qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx to <build-dir>/plugins/qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx.
When you're finished, restart your node.
✔ Yes, let's continue! I've updated --whitelisted-subnets, built my VM, and restarted my node(s)!


2022-10-08T22:42:56.473+0800    info    client/p.go:299 adding subnet validator {"subnetId": "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ", "txFee": 1000000, "start": "2022-10-08T22:43:25.449+0800", "end": "2023-01-31T23:59:28.000+0800", "weight": 1000}
2022-10-08T22:42:57.542+0800    info    platformvm/checker.go:48        polling P-Chain tx      {"txId": "VDvUGzVYMwwKyfwSwvbR8oDy7A7SjnwQEdRVzNm1bsbjzKX1i", "expectedStatus": "Committed"}
2022-10-08T22:42:57.542+0800    info    poll/poll.go:42 start polling   {"internal": "1s"}
2022-10-08T22:42:59.893+0800    info    poll/poll.go:66 poll confirmed  {"took": "2.350718303s"}
added BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx to subnet 2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ validator set (took 2.350718303s)

waiting for validator BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx to start validating 2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ...(could take a few minutes)


2022-10-08T22:46:01.794+0800    info    client/p.go:497 creating blockchain     {"subnetId": "2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ", "chainName": "numbersevm", "vmId": "qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx", "createBlockchainTxFee": 1000000000}
created blockchain "2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE" (took 827.962044ms)

*-------------------------*----------------------------------------------------*
| PRIMARY P-CHAIN ADDRESS | P-avax142ue2exu7qxuawxe34ww8t623lv82tu2vt573g      |
*-------------------------*----------------------------------------------------*
| TOTAL P-CHAIN BALANCE   | 6.9990000 $AVAX                                    |
*-------------------------*----------------------------------------------------*
| URI                     | https://api.avax.network                           |
*-------------------------*----------------------------------------------------*
| NETWORK NAME            | mainnet                                            |
*-------------------------*----------------------------------------------------*
| SUBNET VALIDATORS       | [BXTBUqX8gitUDtVam4fhRWGD1SfeHGoBx]                |
*-------------------------*----------------------------------------------------*
| SUBNET ID               | 2gHgAgyDHQv7jzFg6MxU2yyKq5NZBpwFLFeP8xX2E3gyK1SzSQ |
*-------------------------*----------------------------------------------------*
| BLOCKCHAIN ID           | 2PDRxzc6jMbZSTLb3sufkVszgQc2jtDnYZGtDTAAfom1CTwPsE |
*-------------------------*----------------------------------------------------*
| CHAIN NAME              | numbersevm                                         |
*-------------------------*----------------------------------------------------*
| VM ID                   | qeX7kcVMMkVLB9ZJKTpvtSjpLbtYooNEdpFzFShwRTFu76qdx  |
*-------------------------*----------------------------------------------------*
| VM GENESIS PATH         | ./genesis.json                                     |
*-------------------------*----------------------------------------------------*
```

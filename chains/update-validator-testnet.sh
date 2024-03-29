#!/bin/bash

AVALANCHEGO_PREVIOUS_VERSION="1.10.7"
AVALANCHEGO_VERSION="1.10.11"
SUBNET_EVM_VERSION="0.5.6"
# Numbers Testnet
VM_ID="kmYb53NrmqcW7gfV2FGHBHWXNA6YhhWf7R7LoQeGj9mdDYuaT"
SUBNET_ID="81vK49Udih5qmEzU7opx3Zg9AnB33F2oqUTQKuaoWgCvFUWQe"


download_avalanchego() {
    echo "Step: download_avalanchego"
    wget https://github.com/ava-labs/avalanchego/releases/download/v${AVALANCHEGO_VERSION}/avalanchego-linux-amd64-v${AVALANCHEGO_VERSION}.tar.gz
    tar xzf avalanchego-linux-amd64-v${AVALANCHEGO_VERSION}.tar.gz
    cp avalanchego-v${AVALANCHEGO_PREVIOUS_VERSION}/run.sh avalanchego-v${AVALANCHEGO_VERSION}/
}

download_sunbet_evm() {
    echo "Step: download_sunbet_evm"
    mkdir subnet-evm-${SUBNET_EVM_VERSION}
    wget https://github.com/ava-labs/subnet-evm/releases/download/v${SUBNET_EVM_VERSION}/subnet-evm_${SUBNET_EVM_VERSION}_linux_amd64.tar.gz
    tar xzf subnet-evm_${SUBNET_EVM_VERSION}_linux_amd64.tar.gz -C subnet-evm-${SUBNET_EVM_VERSION}
}

update_subnet_evm() {
    echo "Step: update_subnet_evm"
    cp subnet-evm-${SUBNET_EVM_VERSION}/subnet-evm ~/.avalanchego/plugins/${VM_ID}
    sha256sum subnet-evm-${SUBNET_EVM_VERSION}/subnet-evm ~/.avalanchego/plugins/${VM_ID}
}

show_validator_files() {
    echo "Step: show_validator_files"
    tree avalanchego-v${AVALANCHEGO_VERSION}
    tree ~/.avalanchego/plugins/
}

show_configs() {
    echo "Step: show_configs"
    echo "AVALANCHEGO_PREVIOUS_VERSION: ${AVALANCHEGO_PREVIOUS_VERSION}"
    echo "AVALANCHEGO_VERSION: ${AVALANCHEGO_VERSION}"
    echo "SUBNET_EVM_VERSION: ${SUBNET_EVM_VERSION}"
    echo "VM_ID (Testnet): ${VM_ID}"
    echo "SUBNET_ID (Testnet): ${SUBNET_ID}"
}

show_next_action_reminder() {
    echo "Step: show_next_action_reminder"
    echo "Now, you are ready to start the validator"
    echo "$ cd ~/avalanchego-v${AVALANCHEGO_VERSION}"
    echo "$ ./run.sh"
    echo ""
    echo "Check validators"
    echo "$ cd ~/avalanchego-api-scripts/api"
    echo "$ ./platform.getCurrentValidators.sh ${SUBNET_ID} | jq ."
    echo "$ ./info.peers.sh  | jq ."
}

main() {
    show_configs
    download_avalanchego
    download_sunbet_evm
    update_subnet_evm
    show_validator_files
    show_next_action_reminder
}

main


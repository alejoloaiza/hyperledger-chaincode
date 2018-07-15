#!/bin/bash

set -e

export FABRIC_START_TIMEOUT=10
export MSYS_NO_PATHCONV=1

if [[ $1 == "dev" ]] || [[ $FABRIC_ENV == "dev" ]] ; then
    # Export important variables for composer
    export COMPOSE_PROJECT_NAME=transactiondev
    
    # Remote the keystore already created
    rm -rf ./lib/hfc-key-store
    rm -rf ../lib/hfc-key-store

    cd dev
    # Bring down the network in case it is UP
    docker-compose -f docker-compose-dev.yml down

    # Bring up all images of Hyperledger Fabric
    docker-compose -f docker-compose-dev.yml up 

    #echo ${FABRIC_START_TIMEOUT}
    sleep ${FABRIC_START_TIMEOUT}
    
elif [[ $1 == "qa" ]] || [[ $FABRIC_ENV == "qa" ]] ; then
    # Export important variables for composer
    export COMPOSE_PROJECT_NAME=accountsqa
    #export CC_SRC_PATH=../../chaincode
    export CC_SRC_PATH=github.com/chaincode/
    # Remote the keystore already created
    rm -rf ./lib/hfc-key-store
    rm -rf ../../lib/hfc-key-store

    cd qa1peer

    # Bring down the network in case it is UP
    docker-compose -f docker-compose-qa.yml down

    # Bring up all images of Hyperledger Fabric ... but cli, not yet.
    docker-compose -f docker-compose-qa.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb

    # wait for Hyperledger Fabric to start
    #echo ${FABRIC_START_TIMEOUT}
    sleep ${FABRIC_START_TIMEOUT}

    # Create the channel
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
    # Join peer (peer0.org1.example.com) to the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block


    # Now launch the CLI container in order to install, instantiate chaincode

    docker-compose -f docker-compose-qa.yml up -d cli

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n accounts -v 1.0 -p "$CC_SRC_PATH" 

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n accounts -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    #sleep 10

    # If init is required we should uncomment this, but for now we dont use Init.
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n accounts-nodejs-sdk -c '{"function":"initLedger","Args":[""]}'

fi

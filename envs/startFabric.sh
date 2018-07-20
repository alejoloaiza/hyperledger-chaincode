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
    export COMPOSE_PROJECT_NAME=transactionqa
    #export CC_SRC_PATH=../../chaincode
    export CC_SRC_PATH=github.com/chaincode/
    # Remote the keystore already created
    rm -rf ../hyper-blockchain/lib/hfc-key-store

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

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    #sleep 10

    # If init is required we should uncomment this, but for now we dont use Init.
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n transaction-nodejs-sdk -c '{"function":"initLedger","Args":[""]}'
elif [[ $1 == "qa2" ]] || [[ $FABRIC_ENV == "qa2" ]] ; then

    # Export important variables for composer
    export COMPOSE_PROJECT_NAME=transactionqa2
    #export CC_SRC_PATH=../../chaincode
    export CC_SRC_PATH=github.com/chaincode/
    # Remote the keystore already created
    rm -rf ../hyper-blockchain/lib/hfc-key-store

    cd qa2peer
    # Bring down the network in case it is UP
    docker-compose -f docker-compose-qa2.yml down

    # Bring up all images of Hyperledger Fabric ... but cli, not yet.
    docker-compose -f docker-compose-qa2.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb0 peer1.org1.example.com couchdb1
    #docker-compose -f docker-compose-qa2.yml up -d peer1.org1.example.com 
    # wait for Hyperledger Fabric to start
    #echo ${FABRIC_START_TIMEOUT}
    sleep ${FABRIC_START_TIMEOUT}

    # Create the channel in peer0.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
    # Join peer (peer0.org1.example.com) to the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
    # Fetching the channel in peer1 that was created by peer0
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    # Join peer (peer1.org1.example.com) to the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel join -b mychannel.block

    # Now launch the CLI container in order to install, instantiate chaincode
    sleep 5
    docker-compose -f docker-compose-qa2.yml up -d cli

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 

    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    
    # If init is required we should uncomment this, but for now we dont use Init.
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n transaction-nodejs-sdk -c '{"function":"initLedger","Args":[""]}'

else
    export COMPOSE_PROJECT_NAME=transactionqa2org4peer
    #export CC_SRC_PATH=../../chaincode
    export CC_SRC_PATH=github.com/chaincode/
    # Remote the keystore already created
    rm -rf ../hyper-blockchain/lib/hfc-key-store
    export FABRIC_START_TIMEOUT=15
    cd qa2org4peer
    # Bring down the network in case it is UP
    docker-compose -f docker-compose-qa2org4peer.yml down
    # Bring up the network.
    docker-compose -f docker-compose-qa2org4peer.yml up -d ca-org1.example.com ca-org2.example.com orderer.example.com couchdb0 couchdb1 couchdb2 couchdb3 peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com

    sleep ${FABRIC_START_TIMEOUT}

    # Create the channel in peer0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
    # Fetching the channel in peer1 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel join -b mychannel.block

    docker-compose -f docker-compose-qa2org4peer.yml up -d cli
    sleep 5
    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel join -b mychannel.block

    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer1.org2.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer1.org2.example.com peer channel join -b mychannel.block

    sleep 2
    #Deploy chaincode in all nodes of org1
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
  
    #Deploy chaincode in all nodes of org2
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    #docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer1.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    #docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer1.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
  
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -n transaction -c '{"Args":["CreateAccount", "BC", "123", "ALEJO", "71527525", "pw.123"]}' -C mychannel
    #docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -n transaction -c '{"Args":["CreateAccount", "BC", "432", "ALEJO2", "71527525", "pw.123"]}' -C mychannel
    #docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode invoke -n transaction -c '{"Args":["CreateAccount", "BC", "765", "ALEJO3", "71527525", "pw.123"]}' -C mychannel
    #docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer1.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode invoke -n transaction -c '{"Args":["CreateAccount", "BC", "876", "ALEJO4", "71527525", "pw.123"]}' -C mychannel

fi

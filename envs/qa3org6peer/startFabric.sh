#!/bin/bash

set -e

export FABRIC_START_TIMEOUT=10
export MSYS_NO_PATHCONV=1

    export COMPOSE_PROJECT_NAME=transactionqa3org6peer
    #export CC_SRC_PATH=../../chaincode
    export CC_SRC_PATH=github.com/chaincode/
    # Remote the keystore already created
    rm -rf ../hyper-blockchain/lib/hfc-key-store
    export FABRIC_START_TIMEOUT=15
    #cd qa2org4peer
    # Bring down the network in case it is UP
    docker-compose -f docker-compose-qa3org6peer.yml down
    # Bring up the network.
    docker-compose -f docker-compose-qa3org6peer.yml up -d ca-org1.example.com ca-org2.example.com ca-org3.example.com orderer.example.com couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5 peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com peer0.org3.example.com peer1.org3.example.com

    sleep ${FABRIC_START_TIMEOUT}

    # Create the channel in peer0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block
    # Fetching the channel in peer1 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel join -b mychannel.block

    #docker-compose -f docker-compose-qa2org4peer.yml up -d cli
    sleep 5
    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel join -b mychannel.block

    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer1.org2.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer1.org2.example.com peer channel join -b mychannel.block

    sleep 5
    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer0.org3.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer0.org3.example.com peer channel join -b mychannel.block

    # Fetching the channel in org2 peer 0 and join the channel.
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer1.org3.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer1.org3.example.com peer channel join -b mychannel.block

    sleep 2

    echo "Updating channels with anchors"
    #Update channel config to include anchors
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel update -f /etc/hyperledger/configtx/Org1MSPanchors.tx -c mychannel -o orderer.example.com:7050
    #Update channel config to include anchors
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org2.example.com/msp" peer0.org2.example.com peer channel update -f /etc/hyperledger/configtx/Org2MSPanchors.tx -c mychannel -o orderer.example.com:7050
    #Update channel config to include anchors
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org3.example.com/msp" peer0.org3.example.com peer channel update -f /etc/hyperledger/configtx/Org3MSPanchors.tx -c mychannel -o orderer.example.com:7050

    docker-compose -f docker-compose-qa3org6peer.yml up -d cli
    sleep 2
    #Install and instantiate chaincode in all nodes of org1
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer0.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n transaction -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
    docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 

    #Install and instantiate chaincode in all nodes of org2
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer0.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    docker exec -e "CORE_PEER_LOCALMSPID=Org2MSP" -e "CORE_PEER_ADDRESS=peer1.org2.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 

    #Install and instantiate chaincode in all nodes of org3
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_ADDRESS=peer0.org3.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
    docker exec -e "CORE_PEER_LOCALMSPID=Org3MSP" -e "CORE_PEER_ADDRESS=peer1.org3.example.com:7051" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp" cli peer chaincode install -n transaction -v 1.0 -p "$CC_SRC_PATH" 
  

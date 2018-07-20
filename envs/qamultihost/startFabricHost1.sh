#!/bin/bash

set -e

export FABRIC_START_TIMEOUT=10
export MSYS_NO_PATHCONV=1


# Export important variables for composer
export COMPOSE_PROJECT_NAME=accountsqamultihost
#export CC_SRC_PATH=../../chaincode
#export CC_SRC_PATH=github.com/chaincode/
# Remote the keystore already created
rm -rf ../../lib/hfc-key-store

# Bring down the network in case it is UP
docker-compose -f docker-compose-host1.yml down

# Bring up all images of Hyperledger Fabric ... but cli, not yet.
docker-compose -f docker-compose-host1.yml up
#docker-compose -f docker-compose-qa2.yml up -d peer1.org1.example.com 
# wait for Hyperledger Fabric to start
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel in peer0.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer (peer0.org1.example.com) to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block


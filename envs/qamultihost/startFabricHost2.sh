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
docker-compose -f docker-compose-host2.yml down


# Bring up all images of Hyperledger Fabric ... but cli, not yet.
docker-compose -f docker-compose-host2.yml up
#docker-compose -f docker-compose-qa2.yml up -d peer1.org1.example.com 
# wait for Hyperledger Fabric to start
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Fetching the channel in peer1 that was created by peer0
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel fetch newest mychannel.block -c mychannel --orderer orderer.example.com:7050
# Join peer (peer1.org1.example.com) to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel join -b mychannel.block

# Now launch the CLI container in order to install, instantiate chaincode
#sleep 5
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n accounts-nodejs-sdk -v 1.0 -p "$CC_SRC_PATH" 

#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n accounts-nodejs-sdk -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"

# If init is required we should uncomment this, but for now we dont use Init.
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n accounts-nodejs-sdk -c '{"function":"initLedger","Args":[""]}'

#!/bin/bash
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME="mychannel"
rm -Rf crypto-config
rm -Rf channel-artifacts/*
set -x
cryptogen generate --config=./crypto-config.yaml
set +x
set -x
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
set +x
set -x
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
set +x
set -x
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
set +x
set -x
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
set +x
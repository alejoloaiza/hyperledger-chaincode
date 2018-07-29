#!/bin/bash
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME="mychannel"
rm -Rf crypto-config
rm -Rf channel-artifacts/*
set -x
cryptogen generate --config=./crypto-config.yaml
set +x
set -x
configtxgen -profile 3OrgOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
set +x
set -x
configtxgen -profile 3OrgChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
set +x
set -x
configtxgen -profile 3OrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
set +x
set -x
configtxgen -profile 3OrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
set +x
set -x
configtxgen -profile 3OrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org3MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org3MSP
set +x
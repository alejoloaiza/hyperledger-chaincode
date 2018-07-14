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

fi

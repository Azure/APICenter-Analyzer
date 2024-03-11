#!/bin/bash

set -e

function usage() {
    cat <<USAGE

    Usage: $0 [-e|--environment] [-h|--help]

    Options:
        -e|--environment:   Azure environment name.

        -h|--help:          Show this message.

USAGE

    exit 1
}

AZURE_ENV_NAME=""

if [[ $# -eq 0 ]]; then
    AZURE_ENV_NAME=""
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -e | --environment)
            shift
            AZURE_ENV_NAME="$1"
        ;;

        -h | --help)
            usage
            exit 1
        ;;

        *)
            usage
            exit 1
        ;;
    esac

    shift
done

RESOURCE_GROUP_NAME="rg-$AZURE_ENV_NAME"

repositoryRoot=$(git rev-parse --show-toplevel)

# Provision Azure Event Grid
evtgrd=$(az deployment group create \
    -g $RESOURCE_GROUP_NAME \
    -n "eventgrid-$AZURE_ENV_NAME" \
    --template-file "$repositoryRoot/infra/eventGrid.bicep" \
    --parameters environmentName="$AZURE_ENV_NAME")

#!/bin/bash

set -e

function usage() {
    cat <<USAGE

    Usage: $0 [-e|--environment] [-n|--apic-name] [-h|--help]

    Options:
        -e|--environment:   Azure environment name.
        -n|--apic-name:     API Center name.

        -h|--help:          Show this message.

USAGE

    exit 1
}

AZURE_ENV_NAME=""
APIC_ID=""
APIC_NAME=""
APIC_RESOURCE_GROUP_NAME=""
TOPIC_NAME=""

if [[ $# -eq 0 ]]; then
    AZURE_ENV_NAME=""
    APIC_ID=""
    APIC_NAME=""
    APIC_RESOURCE_GROUP_NAME=""
    TOPIC_NAME=""
fi

while [[ "$1" != "" ]]; do
    case $1 in
        -e | --environment)
            shift
            AZURE_ENV_NAME="$1"
        ;;

        -n | --apic-name)
            shift
            APIC_NAME="$1"
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

REPOSITORY_ROOT=$(git rev-parse --show-toplevel)

# Check whether the function app is deployed and ready for use
function=$(az functionapp function list \
    -g $RESOURCE_GROUP_NAME \
    -n fncapp-$AZURE_ENV_NAME-linter \
    --query "[?name == 'fncapp-$AZURE_ENV_NAME-linter/apicenter-analyzer']")
while [[ -z "$function" ]]
do
    echo "Waiting for the function app to be available ..."

    sleep 10

    function=$(az functionapp function list \
        -g $RESOURCE_GROUP_NAME \
        -n fncapp-$AZURE_ENV_NAME-linter \
        --query "[?name == 'fncapp-$AZURE_ENV_NAME-linter/apicenter-analyzer']")
done

# Check API instance
if [[ -z "$APIC_NAME" ]]; then
    echo "Azure Event Grid will be connected to the new API Center, apic-$AZURE_ENV_NAME."
    APIC_ID=""
    APIC_NAME="apic-$AZURE_ENV_NAME"
    APIC_RESOURCE_GROUP_NAME="$RESOURCE_GROUP_NAME"
    TOPIC_NAME=""
else
    echo "Azure Event Grid will be connected to the existing API Center, $APIC_NAME."
    apic=$(az resource list -n $APIC_NAME)
    if [[ -z "$apic" ]]; then
        echo "API Center instance not found to connect"
        exit 0
    else
        APIC_ID=$(echo $apic | jq -r ".[0].id")
        APIC_RESOURCE_GROUP_NAME=$(echo $apic | jq -r ".[0].resourceGroup")

        echo "Assigning role to $APIC_NAME ..."

        assigned=$(az deployment group create \
            -g $APIC_RESOURCE_GROUP_NAME \
            -n "roleassignment-$AZURE_ENV_NAME" \
            --template-file "$REPOSITORY_ROOT/infra/core/security/roleAssignment.bicep" \
            --parameters environmentName="$AZURE_ENV_NAME" \
            --parameters apicName="$APIC_NAME" \
            --parameters resourceGroupName="$RESOURCE_GROUP_NAME")

        echo "... Assigned"

        TOPIC_NAME=$(az eventgrid system-topic list --query "[?source == '$APIC_ID'] | [0].name" -o tsv)
        if [[ -n "$TOPIC_NAME" ]]; then
            echo "Connecting $APIC_NAME to $TOPIC_NAME ..."
        fi
    fi
fi

# Provision Azure Event Grid
if [[ -z "$APIC_NAME" ]]; then
    echo "Provisioning Azure Event Grid to apic-$AZURE_ENV_NAME ..."
else
    echo "Provisioning Azure Event Grid to $APIC_NAME ..."
fi

evtgrd=$(az deployment group create \
    -g $APIC_RESOURCE_GROUP_NAME \
    -n "eventgrid-$AZURE_ENV_NAME" \
    --template-file "$REPOSITORY_ROOT/infra/apps/eventGrid.bicep" \
    --parameters environmentName="$AZURE_ENV_NAME" \
    --parameters apicId="$APIC_ID" \
    --parameters apicName="$APIC_NAME" \
    --parameters topicName="$TOPIC_NAME")

echo "... Provisioned"

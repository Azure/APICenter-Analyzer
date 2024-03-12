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

if [[ $# -eq 0 ]]; then
    AZURE_ENV_NAME=""
    APIC_ID=""
    APIC_NAME=""
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

repositoryRoot=$(git rev-parse --show-toplevel)

# Check API instance
if [[ -z "$APIC_NAME" ]]; then
    echo "Azure Event Grid will be connected to the new API Center, apic-$AZURE_ENV_NAME."
    APIC_ID=""
    APIC_NAME=""
else
    echo "Azure Event Grid will be connected to the existing API Center, $APIC_NAME."
    apic=$(az resource list -n $APIC_NAME)
    if [[ -z "$apic" ]]; then
        echo "API Center instance not found to connect"
        exit 0
    else
        APIC_ID=$(echo $apic | jq -r ".[0].id")
        RESOURCE_GROUP_NAME=$(echo $apic | jq -r ".[0].resourceGroup")

        echo "Assigning role to $APIC_NAME ..."

        ROLE_DEFINITION_ID=$(az role definition list -n "b24988ac-6180-42a0-ab88-20f7382dd24c" --scope $APIC_ID --query "[0].id" -o tsv)
        PRINCIPAL_ID=$(az resource list -n "fncapp-$AZURE_ENV_NAME-linter" --query "[0].identity.principalId" -o tsv)
        assigned=$(az role assignment create --role $ROLE_DEFINITION_ID --scope $APIC_ID --assignee-object-id $PRINCIPAL_ID --assignee-principal-type ServicePrincipal)

        echo "... Assigned"
    fi
fi

# Provision Azure Event Grid
if [[ -z "$APIC_NAME" ]]; then
    echo "Provisioning Azure Event Grid to apic-$AZURE_ENV_NAME ..."
else
    echo "Provisioning Azure Event Grid to $APIC_NAME ..."
fi

evtgrd=$(az deployment group create \
    -g $RESOURCE_GROUP_NAME \
    -n "eventgrid-$AZURE_ENV_NAME" \
    --template-file "$repositoryRoot/infra/eventGrid.bicep" \
    --parameters environmentName="$AZURE_ENV_NAME" \
    --parameters apicId="$APIC_ID" \
    --parameters apicName="$APIC_NAME")

echo "... Provisioned"

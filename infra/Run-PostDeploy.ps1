# Run post-deploy script
Param(
    [string]
    [Parameter(Mandatory = $false)]
    $Environment,

    [string]
    [Parameter(Mandatory = $false)]
    $ApicName,

    [switch]
    [Parameter(Mandatory = $false)]
    $Help
)

function Show-Usage {
    Write-Output "    This runs the post-deploy scripts

    Usage: $(Split-Path $MyInvocation.ScriptName -Leaf) ``
            [-Environment   <Azure environment name>] ``
            [-ApicName      <API Center name>] ``

            [-Help]

    Options:
        -Environment        Azure environment name.
        -ApicName           API Center name.

        -Help:              Show this message.
"

    Exit 0
}

# Show usage
$needHelp = $Help -eq $true
if ($needHelp -eq $true) {
    Show-Usage
    Exit 0
}

if ($Environment -eq $null) {
    Show-Usage
    Exit 0
}

$AZURE_ENV_NAME = $Environment
$RESOURCE_GROUP_NAME = "rg-$AZURE_ENV_NAME"
$APIC_ID = ""
$APIC_NAME = "$ApicName"
$APIC_RESOURCE_GROUP_NAME = ""
$TOPIC_NAME = ""

$REPOSITORY_ROOT = git rev-parse --show-toplevel

# Check APIC instance
if (($APIC_NAME -eq $null) -or ($APIC_NAME -eq "")) {
    Write-Output "Azure Event Grid will be connected to the new API Center, apic-$AZURE_ENV_NAME."
    $APIC_ID = ""
    $APIC_NAME = "$ApicName"
    $APIC_RESOURCE_GROUP_NAME = "$RESOURCE_GROUP_NAME"
    $TOPIC_NAME = ""
}
else {
    Write-Output "Azure Event Grid will be connected to the existing API Center, $APIC_NAME."
    $apic = az resource list -n $APIC_NAME | ConvertFrom-Json
    if ($apic -eq $null) {
        Write-Output "API Center instance not found to connect"
        Exit 0
    }
    else {
        $APIC_ID = $apic[0].id
        $APIC_NAME = "$ApicName"
        $APIC_RESOURCE_GROUP_NAME = $apic[0].resourceGroup

        Write-Output "Assigning role to $APIC_NAME ..."

        $assigned = az deployment group create `
            -g $APIC_RESOURCE_GROUP_NAME `
            -n "roleassignment-$AZURE_ENV_NAME" `
            --template-file "$($REPOSITORY_ROOT)/infra/roleAssignment.bicep" `
            --parameters environmentName="$AZURE_ENV_NAME" `
            --parameters apicName="$APIC_NAME" `
            --parameters resourceGroupName="$RESOURCE_GROUP_NAME"

        Write-Output "... Assigned"

        $TOPIC_NAME = az eventgrid system-topic list --query "[?source == '$APIC_ID'] | [0].name" -o tsv
        if (($TOPIC_NAME -ne $null) -and ($TOPIC_NAME -ne "")) {
            Write-Output "Connecting $APIC_NAME to $TOPIC_NAME ..."
        }
    }
}

# Provision Azure Event Grid
Write-Output "Provisioning Azure Event Grid to $(($APIC_NAME -eq $null) -or ($APIC_NAME -eq '') ? "apic-$AZURE_ENV_NAME" : $APIC_NAME) ..."

$evtgrd = az deployment group create `
    -g $APIC_RESOURCE_GROUP_NAME `
    -n "eventgrid-$AZURE_ENV_NAME" `
    --template-file "$($REPOSITORY_ROOT)/infra/eventGrid.bicep" `
    --parameters environmentName="$AZURE_ENV_NAME" `
    --parameters apicId="$APIC_ID" `
    --parameters apicName="$APIC_NAME" `
    --parameters topicName="$TOPIC_NAME"

Write-Output "... Provisioned"

# Run post-deploy script
Param(
    [string]
    [Parameter(Mandatory = $false)]
    $Environment,

    [switch]
    [Parameter(Mandatory = $false)]
    $Help
)

function Show-Usage {
    Write-Output "    This runs the post-deploy scripts

    Usage: $(Split-Path $MyInvocation.ScriptName -Leaf) ``
            [-Environment   <Azure environment name>] ``

            [-Help]

    Options:
        -Environment        Azure environment name.

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

$repositoryRoot = git rev-parse --show-toplevel

# Provision Azure Event Grid
Write-Output "Provisioning Azure Event Grid ..."

$evtgrd = az deployment group create `
    -g $RESOURCE_GROUP_NAME `
    -n "eventgrid-$AZURE_ENV_NAME" `
    --template-file "$($repositoryRoot)/infra/eventGrid.bicep" `
    --parameters environmentName="$AZURE_ENV_NAME"

Write-Output "... Provisioned"

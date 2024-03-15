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

$repositoryRoot = git rev-parse --show-toplevel

# Check APIC instance
if (($ApicName -eq $null) -or ($ApicName -eq "")) {
    Write-Output "Azure Event Grid will be connected to the new API Center, apic-$AZURE_ENV_NAME."
    $apicId = ""
    $apicName = ""
    $topicName = ""
}
else {
    Write-Output "Azure Event Grid will be connected to the existing API Center, $ApicName."
    $apic = az resource list -n $ApicName | ConvertFrom-Json
    if ($apic -eq $null) {
        Write-Output "API Center instance not found to connect"
        Exit 0
    }
    else {
        $apicId = $apic[0].id
        $apicName = $ApicName
        $RESOURCE_GROUP_NAME = $apic[0].resourceGroup

        Write-Output "Assigning role to $apicName ..."

        $rdId = az role definition list -n "b24988ac-6180-42a0-ab88-20f7382dd24c" --scope $apicId --query "[0].id" -o tsv
        $principalId = az resource list -n "fncapp-$AZURE_ENV_NAME-linter" --query "[0].identity.principalId" -o tsv
        $assigned = az role assignment create --role $rdId --scope $apicId --assignee-object-id $principalId --assignee-principal-type ServicePrincipal

        Write-Output "... Assigned"

        $topicName = az eventgrid system-topic list --query "[?source == '$apicId'] | [0].name" -o tsv
        if (($topicName -ne $null) -and ($topicName -ne "")) {
            Write-Output "Connecting $apicName to $topicName ..."
        }
    }
}

# Provision Azure Event Grid
Write-Output "Provisioning Azure Event Grid to $(($ApicName -eq $null) -or ($ApicName -eq '') ? "apic-$AZURE_ENV_NAME" : $apicName) ..."

$evtgrd = az deployment group create `
    -g $RESOURCE_GROUP_NAME `
    -n "eventgrid-$AZURE_ENV_NAME" `
    --template-file "$($repositoryRoot)/infra/eventGrid.bicep" `
    --parameters environmentName="$AZURE_ENV_NAME" `
    --parameters apicId="$apicId" `
    --parameters apicName="$apicName" `
    --parameters topicName="$topicName"

Write-Output "... Provisioned"

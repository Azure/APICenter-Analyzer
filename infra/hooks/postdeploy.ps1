# PowerShell syntax
Write-Host "Configuring EventGrid subscription for API Center"

# Sleep for 2 minutes to allow the function app to be deployed
Start-Sleep -s 120

# Load the azd environment variables
$DIR = Split-Path $MyInvocation.MyCommand.Path
& "$DIR\load_azd_env.ps1"

$azureFunctionId = az functionapp function show --name $env:AZURE_FUNCTION_NAME --function-name apicenter-analyzer --resource-group $env:RESOURCE_GROUP_NAME --query "id" --output tsv
az eventgrid event-subscription create --name on-api-definition-added-or-updated --source-resource-id "$env:AZURE_API_CENTER_ID" --endpoint "$azureFunctionId" --endpoint-type azurefunction --included-event-types Microsoft.ApiCenter.ApiDefinitionAdded Microsoft.ApiCenter.ApiDefinitionUpdated

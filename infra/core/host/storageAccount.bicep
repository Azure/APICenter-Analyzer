param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param tags object = {}

var shortname = '${replace(replace(environmentName, '-', ''), '_', '')}${suffix}'

resource st 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${shortname}'
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
  }
}

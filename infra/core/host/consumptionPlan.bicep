param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource csplan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'csplan-${longname}'
  location: location
  kind: 'functionApp'
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

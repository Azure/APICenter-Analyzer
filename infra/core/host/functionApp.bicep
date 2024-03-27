param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location
param useMonitoring bool = true

@allowed([
  '18'
  '20'
])
param nodeVersion string = '18'

param tags object = {}

var shortname = '${replace(replace(environmentName, '-', ''), '_', '')}${suffix}'
var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource st 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: 'st${shortname}'
}

resource appins 'Microsoft.Insights/components@2020-02-02' existing = {
  name: 'appins-${longname}'
}

resource csplan 'Microsoft.Web/serverfarms@2023-01-01' existing = {
  name: 'csplan-${longname}'
}

var commonSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${st.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${st.listKeys().keys[0].value}'
  }
  {
    name: 'FUNCTION_APP_EDIT_MODE'
    value: 'readonly'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'node'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${st.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${st.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: 'fncapp-${longname}'
  }
]

var appSettings = concat(
  commonSettings,
  useMonitoring == true
    ? [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: useMonitoring == true ? appins.properties.InstrumentationKey : null
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: useMonitoring == true ? appins.properties.ConnectionString : null
        }
      ]
    : []
)

resource fncapp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'fncapp-${longname}'
  location: location
  kind: 'functionapp,linux'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: csplan.id
    httpsOnly: true
    reserved: true
    siteConfig: {
      appSettings: appSettings
      linuxFxVersion: 'Node|${nodeVersion}'
    }
  }
}

var policies = [
  {
    name: 'scm'
    allow: false
  }
  {
    name: 'ftp'
    allow: false
  }
]

resource fncappPolicies 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-01-01' = [
  for policy in policies: {
    name: policy.name
    parent: fncapp
    properties: {
      allow: policy.allow
    }
  }
]

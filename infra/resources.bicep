param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location
param useMonitoring bool = true
param apicName string = ''

param tags object = {}

var shortname = '${replace(replace(environmentName, '-', ''), '_', '')}${suffix}'
var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource apic 'Microsoft.ApiCenter/services@2024-03-01' =
  if (apicName == null || apicName == '') {
    name: 'apic-${environmentName}'
    location: location
    tags: tags
    identity: {
      type: 'SystemAssigned'
    }
  }

resource apicWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-03-01' =
  if (apicName == null || apicName == '') {
    name: 'default'
    parent: apic
    properties: {
      title: 'Default Workspace'
      description: 'Default workspace'
    }
  }

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

resource wrkspc 'Microsoft.OperationalInsights/workspaces@2022-10-01' =
  if (useMonitoring == true) {
    name: 'wrkspc-${longname}'
    location: location
    tags: tags
    properties: {
      sku: {
        name: 'PerGB2018'
      }
      retentionInDays: 30
      workspaceCapping: {
        dailyQuotaGb: -1
      }
      publicNetworkAccessForIngestion: 'Enabled'
      publicNetworkAccessForQuery: 'Enabled'
    }
  }

resource appins 'Microsoft.Insights/components@2020-02-02' =
  if (useMonitoring == true) {
    name: 'appins-${longname}'
    location: location
    kind: 'web'
    tags: tags
    properties: {
      Application_Type: 'web'
      Flow_Type: 'Bluefield'
      IngestionMode: 'LogAnalytics'
      Request_Source: 'rest'
      WorkspaceResourceId: wrkspc.id
    }
  }

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
      linuxFxVersion: 'Node|18'
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

module roleAssignment './roleAssignment.bicep' =
  if (apicName == null || apicName == '') {
    name: 'apic-${environmentName}-role-assignment'
    dependsOn: [
      apic
      fncapp
    ]
    params: {
      environmentName: environmentName
      apicName: 'apic-${environmentName}'
    }
  }

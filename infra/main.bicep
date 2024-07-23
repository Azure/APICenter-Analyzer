targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed([
  'australiaeast'
  'centralindia'
  'eastus'
  'uksouth'
  'westeurope'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string

@description('Should monitoring resources be provisioned?')
param useMonitoring bool

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param functionName string = ''
param appServicePlanName string = ''
param storageAccountName string = ''
param apiCenterName string
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param applicationInsightsDashboardName string = ''
param diagnosticsSettingsName string = ''

param resourceGroupName string = ''
param apiCenterResourceGroupName string

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var createAPIC = apiCenterName != '' ? false : true

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

resource apiCenterRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!createAPIC) {
  name: apiCenterResourceGroupName
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'Y1'
    }
    kind: 'linux'
  }
}

// Create the storage account
module storageAccount './core/storage/storage-account.bicep' = {
  name: 'storageaccount'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    allowBlobPublicAccess: false
  }
}

// Create the function
module function './core/host/functions.bicep' = {
  name: 'functionapp'
  scope: rg
  params: {
    name: !empty(functionName) ? functionName : '${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'function' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'node'
    runtimeVersion: '18'
    storageAccountName: storageAccount.outputs.name
    managedIdentity: true
    applicationInsightsName: useMonitoring ? monitoring.outputs.applicationInsightsName : ''
    alwaysOn: false
  }
}

// Integrate Diagnostics settings
module diagnostics './core/monitor/appservice-diagnosticsettings.bicep' = if (useMonitoring) {
  name: 'diagnostics'
  scope: rg
  params: {
    name: !empty(diagnosticsSettingsName) ? diagnosticsSettingsName : 'diag-${resourceToken}'
    logAnalyticsName: monitoring.outputs.logAnalyticsWorkspaceName
    appServiceName: function.outputs.name
    kind: 'functionapp'
  }
}

// Create the api center
module apiCenter './core/gateway/api-center.bicep' = if (createAPIC) {
  name: 'apicenter'
  scope: rg
  params: {
    name: !empty(apiCenterName) ? apiCenterName : 'apic-${resourceToken}'
    location: location
    tags: tags
  }
}

// Give api center access to the function
module apiCenterAccess './core/security/apicenter-access.bicep' = if (createAPIC) {
  name: 'apicenteraccess'
  scope: rg
  params: {
    apiCenterName: createAPIC ? apiCenter.outputs.name : apiCenterName
    principalId: function.outputs.identityPrincipalId
  }
}

// Give api center access to the function if api center exists
module apiCenterExistAccess './core/security/apicenter-access.bicep' = if (!createAPIC) {
  name: 'apicenteraccessexist'
  scope: apiCenterRG
  params: {
    apiCenterName: createAPIC ? apiCenter.outputs.name : apiCenterName
    principalId: function.outputs.identityPrincipalId
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = if (useMonitoring) {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName)
      ? logAnalyticsName
      : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName)
      ? applicationInsightsName
      : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName)
      ? applicationInsightsDashboardName
      : '${abbrs.portalDashboards}${resourceToken}'
  }
}

output RESOURCE_GROUP_NAME string = rg.name
output AZURE_API_CENTER_ID string = createAPIC
  ? apiCenter.outputs.id
  : resourceId(subscription().subscriptionId, apiCenterRG.name, 'Microsoft.ApiCenter/services', apiCenterName)
output AZURE_FUNCTION_NAME string = function.outputs.name
output APIC_NAME string = createAPIC ? apiCenter.outputs.name : apiCenterName
output APIC_RESOURCE_GROUP_NAME string = createAPIC ? rg.name : apiCenterRG.name
output USE_MONITORING bool = useMonitoring

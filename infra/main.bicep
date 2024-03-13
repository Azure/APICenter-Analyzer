targetScope = 'subscription'

@minLength(1)
@maxLength(18)
@description('Name of the environment that can be used as part of naming resource convention')
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
param location string

@description('Should monitoring resources be provisioned?')
@allowed([
  'yes'
  'no'
])
param useMonitoring string

@description('API Center instance name to connect. (e.g. apic-linter1234, etc.) If not provided, a new API Center instance will be provisioned.')
param apicName string

// Tags that should be applied to all resources.
//
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module resources './resources.bicep' = {
  name: 'Resources'
  scope: rg
  params: {
    environmentName: environmentName
    suffix: 'linter'
    location: location
    useMonitoring: useMonitoring == 'yes' ? true : false
    apicName: apicName
    tags: tags
  }
}

output USE_MONITORING string = useMonitoring
output APIC_NAME string = apicName
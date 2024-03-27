param environmentName string
param suffix string = 'linter'
param apicName string
param resourceGroupName string = resourceGroup().name

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource apic 'Microsoft.ApiCenter/services@2024-03-01' existing = {
  name: apicName
}

resource fncapp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: 'fncapp-${longname}'
  scope: resourceGroup(resourceGroupName)
}

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: apic
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, fncapp.id, contributorRoleDefinition.id)
  scope: apic
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: fncapp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

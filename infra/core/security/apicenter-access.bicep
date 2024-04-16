metadata description = 'Assigns API Center Compliance Manager permissions to access an Azure Function.'
param apiCenterName string
param principalId string

var apicManagerRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)

resource apicManager 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: apiCenter // Use when specifying a scope that is different than the deployment scope
  name: guid(subscription().id, resourceGroup().id, principalId, apicManagerRole)
  properties: {
    roleDefinitionId: apicManagerRole
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' existing = {
  name: apiCenterName
}

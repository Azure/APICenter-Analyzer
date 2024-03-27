param environmentName string
param location string = resourceGroup().location

param tags object = {}

resource apic 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: 'apic-${environmentName}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

resource apicWorkspace 'Microsoft.ApiCenter/services/workspaces@2024-03-01' = {
  name: 'default'
  parent: apic
  properties: {
    title: 'Default Workspace'
    description: 'Default workspace'
  }
}

param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource wrkspc 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: 'wrkspc-${longname}'
}

resource appins 'Microsoft.Insights/components@2020-02-02' = {
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

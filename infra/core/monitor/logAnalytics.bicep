param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource wrkspc 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
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

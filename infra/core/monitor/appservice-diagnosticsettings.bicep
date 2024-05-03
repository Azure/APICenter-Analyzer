metadata description = 'Creates a diagnostics settings and integrate it with an App Service instance and Log Analytics Workspace instance.'
param name string

param logAnalyticsName string
param appServiceName string

@allowed([
  'functionapp'
  'appservice'
])
param kind string = 'appservice'

var diagnosticLogCategoriesToEnable = kind == 'functionapp'
  ? [
      'FunctionAppLogs'
      'AppServiceAuthenticationLogs'
    ]
  : [
      'AppServiceHTTPLogs'
      'AppServiceConsoleLogs'
      'AppServiceAppLogs'
      'AppServiceAuditLogs'
      'AppServiceIPSecAuditLogs'
      'AppServicePlatformLogs'
    ]

var diagnosticMetricsToEnable = [
  'AllMetrics'
]

var diagnosticsLogs = [
  for category in diagnosticLogCategoriesToEnable: {
    category: category
    enabled: true
  }
]

var diagnosticsMetrics = [
  for metric in diagnosticMetricsToEnable: {
    category: metric
    timeGrain: null
    enabled: true
  }
]

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsName
}
resource appService 'Microsoft.Web/sites@2022-03-01' existing = {
  name: appServiceName
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: name
  scope: appService
  properties: {
    workspaceId: logAnalytics.id
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
}

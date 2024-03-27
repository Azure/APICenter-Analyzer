param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param useMonitoring bool = true
param apicName string = ''

param tags object = {}

var shortname = '${replace(replace(environmentName, '-', ''), '_', '')}${suffix}'
var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

module apic './apps/apiCenter.bicep' =
  if (empty(apicName) == true) {
    name: 'module-apic-${environmentName}'
    params: {
      environmentName: environmentName
      location: location
      tags: tags
    }
  }

module st './core/host/storageAccount.bicep' = {
  name: 'module-st-${shortname}'
  params: {
    environmentName: environmentName
    suffix: suffix
    location: location
    tags: tags
  }
}

module wrkspc './core/monitor/logAnalytics.bicep' =
  if (useMonitoring == true) {
    name: 'module-wrkspc-${longname}'
    params: {
      environmentName: environmentName
      suffix: suffix
      location: location
      tags: tags
    }
  }

module appins './core/monitor/applicationInsights.bicep' =
  if (useMonitoring == true) {
    name: 'module-appins-${longname}'
    dependsOn: [
      wrkspc
    ]
    params: {
      environmentName: environmentName
      suffix: suffix
      location: location
      tags: tags
    }
  }

module csplan './core/host/consumptionPlan.bicep' = {
  name: 'module-csplan-${longname}'
  params: {
    environmentName: environmentName
    suffix: suffix
    location: location
    tags: tags
  }
}

module fncapp './core/host/functionApp.bicep' = {
  name: 'module-fncapp-${longname}'
  dependsOn: [
    appins
    csplan
    st
  ]
  params: {
    environmentName: environmentName
    suffix: suffix
    location: location
    useMonitoring: useMonitoring
    nodeVersion: '18'
    tags: tags
  }
}

module roleAssignment './core/security/roleAssignment.bicep' =
  if (empty(apicName) == true) {
    name: 'module-apic-${environmentName}-role-assignment'
    dependsOn: [
      apic
      fncapp
    ]
    params: {
      environmentName: environmentName
      suffix: suffix
      apicName: 'apic-${environmentName}'
    }
  }

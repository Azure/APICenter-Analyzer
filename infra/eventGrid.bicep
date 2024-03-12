param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location
param apicName string = ''
param apicId string = ''

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource apic 'Microsoft.ApiCenter/services@2024-03-01' existing = if (apicId == null || apicId == '') {
  name: 'apic-${environmentName}'
}

resource evtgrdSystemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: 'evtgrdtpc-${apicName != null && apicName != '' ? apicName : 'apic-${environmentName}'}-on-api-definition-added-or-updated'
  location: location
  tags: tags
  properties: {
    source: apicId != null && apicId != '' ? apicId : apic.id
    topicType: 'Microsoft.ApiCenter.Services'
  }
}

resource evtgrdSystemTopicSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: 'evtgrdsub-fncapp-${longname}'
  parent: evtgrdSystemTopic
  properties: {
    destination: {
      properties: {
        resourceId: resourceId('rg-${environmentName}', 'Microsoft.Web/sites/functions', 'fncapp-${longname}', 'apicenter-analyzer')
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.ApiCenter.ApiDefinitionAdded'
        'Microsoft.ApiCenter.ApiDefinitionUpdated'
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
  }
}

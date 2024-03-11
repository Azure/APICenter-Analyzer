param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

resource apic 'Microsoft.ApiCenter/services@2024-03-01' existing = {
  name: 'apic-${environmentName}'
}

resource evtgrdSystemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = {
  name: 'evtgrdtpc-apic-${longname}-on-api-definition-added-or-updated'
  location: location
  tags: tags
  properties: {
    source: apic.id
    topicType: 'Microsoft.ApiCenter.Services'
  }
}

resource fncappFunction 'Microsoft.Web/sites/functions@2023-01-01' existing = {
  name: 'fncapp-${longname}/apicenter-analyzer'
}

resource evtgrdSystemTopicSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: 'evtgrdsub-fncapp-${longname}'
  parent: evtgrdSystemTopic
  properties: {
    destination: {
      properties: {
        resourceId: fncappFunction.id
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
      endpointType: 'AzureFunction'
    }
    filter: {
      includedEventTypes: [
        'Microsoft.ApiCenter.ApiDefinitionAdded'
        'Microsoft.ApiCenter.ApiDefinitionUpdated'
      ]
      enableAdvancedFilteringOnArrays: true
    }
    labels: []
    eventDeliverySchema: 'EventGridSchema'
    retryPolicy: {
      maxDeliveryAttempts: 30
      eventTimeToLiveInMinutes: 1440
    }
  }
}

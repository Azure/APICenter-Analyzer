param environmentName string
param suffix string = 'linter'
param location string = resourceGroup().location

param apicId string = ''
param apicName string = ''
param topicName string = ''

param tags object = {}

var longname = '${environmentName}${suffix == null || suffix == '' ? '' : '-'}${suffix}'

var isApicNewOrExisting = apicId == null || apicId == '' ? 'new' : 'existing'
var isTopicNewOrExisting = topicName == null || topicName == '' ? 'new' : 'existing'

resource apic 'Microsoft.ApiCenter/services@2024-03-01' existing = if (isApicNewOrExisting == 'new') {
  name: 'apic-${environmentName}'
}

resource evtgrdSystemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = if (isTopicNewOrExisting == 'new') {
  name: 'evtgrdtpc-${isApicNewOrExisting == 'new' ? 'apic-${environmentName}' : apicName}-on-api-definition-added-or-updated'
  location: location
  tags: tags
  properties: {
    source: isApicNewOrExisting == 'new' ? apic.id : apicId
    topicType: 'Microsoft.ApiCenter.Services'
  }
}

resource evtgrdSystemTopicExisting 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' existing = if (isTopicNewOrExisting == 'existing') {
  name: topicName
}

resource evtgrdSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2023-12-15-preview' = {
  name: '${isTopicNewOrExisting == 'new' ? evtgrdSystemTopic.name : evtgrdSystemTopicExisting.name}/evtgrdsub-fncapp-${longname}'
  properties: {
    destination: {
      properties: {
        resourceId: resourceId(
          'rg-${environmentName}',
          'Microsoft.Web/sites/functions',
          'fncapp-${longname}',
          'apicenter-analyzer'
        )
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

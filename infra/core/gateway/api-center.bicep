param name string
param location string
param tags object

// Create an API center service
resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: name
  location: location
  tags: tags
}

output name string = apiCenter.name
output id string = apiCenter.id

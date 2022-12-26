param location string = resourceGroup().location
param name string = 'cr${uniqueString(resourceGroup().id)}'

resource cr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: name
  location: location
  properties: {
    adminUserEnabled: true
  }
  sku: {
    name: 'Premium'
  } 
}

output ID string = cr.id
output name string = cr.name

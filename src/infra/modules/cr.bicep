param location string = resourceGroup().location
param name string

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

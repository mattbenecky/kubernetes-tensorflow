param location string = resourceGroup().location
param name string
param privateLinkServiceConnections array
param snetID object

resource pep 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: name
  location: location
  properties: {
    subnet: snetID
    privateLinkServiceConnections: privateLinkServiceConnections
  }
}

output name string = pep.name

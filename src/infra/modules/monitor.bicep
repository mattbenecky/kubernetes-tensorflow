param name string

// Currently only available in East US, ... tba
param location string = 'eastus'
param tags object

// ---------
// RESOURCES
// ---------

resource monitor 'Microsoft.Monitor/accounts@2021-06-03-preview' = {
  location: location
  name: name
  tags: tags
}

output ID string = monitor.id

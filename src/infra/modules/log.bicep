// ----------
// PARAMETERS
// ----------

@description('The resource name')
@minLength(4)
@maxLength(63)
param name string

@description('The geo-location where the resource lives')
param location string =  resourceGroup().location
param tags object

// ----------
// VARIABLES
// ----------

var workspace = {
  name: 'log-${name}-${uniqueString(resourceGroup().id)}'
  location: location
  skuName: 'PerGB2018'
}

// ---------
// RESOURCES
// ---------

resource log 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspace.name
  location: workspace.location
  tags: tags
  properties: {
    sku: {
      name: workspace.skuName
    }
  }
}

output workspaceID string = log.id
output workspaceName string = log.name

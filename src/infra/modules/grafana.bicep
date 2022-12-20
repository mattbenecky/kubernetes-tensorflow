param location string = resourceGroup().location
param name string

param azureMonitorWorkspaceResourceId string
param skuName string = 'Standard'
param tags object

var identity = {
  type: 'SystemAssigned'
}

var sku = {
  name: skuName
}

resource grafana 'Microsoft.Dashboard/grafana@2022-08-01' = {
  identity: identity
  location: location
  name: name
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: azureMonitorWorkspaceResourceId
        }
      ]
    }
  }
  sku: sku
  tags: tags
}

output principalID string = grafana.identity.principalId
output ID string = grafana.id

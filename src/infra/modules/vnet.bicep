// ----------
// PARAMETERS
// ----------

param name string
param location string =  resourceGroup().location
param tags object 

@description('When creating VNet, you must specify a custom private IP address space using public and private (RFC 1918) addresses.')
param addressSpace object 

@description('Subnets to segment VNet into one or more sub-networks and allocate a portion of the address space to each subnet.')
param subnets array

// ----------
// VARIABLES
// ----------

var virtualNetwork = {
  name: 'vnet-${name}'
  location: location
  enableDdosProtection: false
}

// ---------
// RESOURCES
// ---------

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: virtualNetwork.name
  location: virtualNetwork.location
  tags: tags
  properties: {
    addressSpace: addressSpace 
    subnets: [for subnet in subnets: {
      name: 'snet-${subnet.name}'
      properties: {
        addressPrefix: subnet.addressPrefix
        serviceEndpoints: contains(subnet, 'serviceEndpoints') ? subnet.serviceEndpoints : []
        delegations: contains(subnet, 'delegation') ? subnet.delegation : []
        privateEndpointNetworkPolicies: contains(subnet, 'privateEndpointNetworkPolicies') ? subnet.privateEndpointNetworkPolicies : null
        privateLinkServiceNetworkPolicies: contains(subnet, 'privateLinkServiceNetworkPolicies') ? subnet.privateLinkServiceNetworkPolicies : null
      }
    }]
    enableDdosProtection: virtualNetwork.enableDdosProtection
  }
}

output vnetID string = vnet.id
output vnetName string = vnet.name
output vnetSubnets array = vnet.properties.subnets
output snetID string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.properties.subnets[0].name)

output ID object = {
  id: vnet.id
}

output subnets array = [for (subnet, i) in subnets: {
  id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.properties.subnets[i].name)
}]

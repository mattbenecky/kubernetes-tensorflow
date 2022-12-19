// ----------
// PARAMETERS
// ----------

param azurePolicy object = loadJsonContent('../variables/aks.json', 'addOnProfiles.azurePolicy')

param name string
param location string =  resourceGroup().location
param tags object 
param dnsPrefix string = toLower('aks-${uniqueString(resourceGroup().id)}')
param adminGroupID string
param privateDNSZoneID string
param workspaceID string
param userAssignedID string
param apiServerSubnetID string

@description('Resource ID of virtual network subnet used for nodes and/or pods IP assignment.')
param vnetSubnetID string

@allowed(['1.25.2'])
param kubernetesVersion string = loadJsonContent('../variables/aks.json', 'kubernetesVersion')

@allowed(['Basic'])
param skuName string = loadJsonContent('../variables/aks.json', 'sku.name')

@allowed(['Free'])
param skuTier string = loadJsonContent('../variables/aks.json', 'sku.tier')

@allowed(['basic','standard'])
@description('loadBalancerSku property')
param loadBalancerSku string = loadJsonContent('../variables/aks.json', 'networkProfile.loadBalancerSku')

@allowed(['azure','kubenet'])
@description('networkPlugin property')
param networkPlugin string = loadJsonContent('../variables/aks.json', 'networkProfile.networkPlugin')

param agentPools array = loadJsonContent('../variables/aks.json', 'agentPoolProfiles')

// ----------
// VARIABLES
// ----------

@description('Object variable loads aadProfile object from aks.json variable file and joins adminGroupObjectIDs object') 

var aadProfile = {
  adminGroupObjectIDs: adminGroupObjectIDs
  enableAzureRBAC: true
  managed: true
  tenantID: subscription().tenantId
}

var identity = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userAssignedID}': {}
  }
}

var apiServerAccessProfile = {
  //authorizedIPRanges: [
  //  ''
  //]
  disableRunCommand: false
  enablePrivateCluster: true
  enablePrivateClusterPublicFQDN: false
  enableVnetIntegration: true
  privateDNSZone: privateDNSZoneID
  subnetId: apiServerSubnetID
}

var adminGroupObjectIDs = [adminGroupID]

var agentPoolProfiles = [for agentPool in agentPools:{
  count: agentPool.Count
  enableAutoScaling: true
  enableNodePublicIP: false
  maxCount: agentPool.maxCount
  maxPods: agentPool.maxPods
  minCount: agentPool.minCount
  mode: agentPool.mode
  name: agentPool.name
  nodeTaints: []
  osType: agentPool.osType
  type: agentPool.type
  vmSize: agentPool.vmSize
  vnetSubnetID: vnetSubnetID
}]

var httpApplicationRouting = {
  enabled: false
}

@description('Object variable networkProfile properties')
var networkProfile = {
  dockerBridgeCidr: '172.17.0.1/16'
  loadBalancerSku: loadBalancerSku
  networkPlugin: networkPlugin
}

var omsagent = {
  config: {
    logAnalyticsWorkspaceResourceID: workspaceID
  }
  enabled: true
}

var sku = {
  name: skuName
  tier: skuTier
}

var properties = union( {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix
  }, 
  //identity, 
  sku, 
  aadProfile, 
  networkProfile
)

var cluster = {
  name: 'aks-${name}'
  location: location
  dnsPrefix: dnsPrefix
}

// ---------
// RESOURCES
// ---------

resource aks 'Microsoft.ContainerService/managedClusters@2022-09-02-preview' = {
  identity: identity
  location: cluster.location
  name: cluster.name
  properties: {
    aadProfile: aadProfile
    addonProfiles: {
      azurePolicy: azurePolicy
      httpApplicationRouting: httpApplicationRouting
      omsagent: omsagent
    }
    agentPoolProfiles: agentPoolProfiles
    apiServerAccessProfile: apiServerAccessProfile
    disableLocalAccounts: true
    dnsPrefix: cluster.dnsPrefix
    enableRBAC: true
    kubernetesVersion: properties.kubernetesVersion
    networkProfile: networkProfile 
    nodeResourceGroup: 'rg-aks-node-${name}'
    //publicNetworkAccess: 'SecuredByPerimeter'
    publicNetworkAccess: 'Disabled'
  }
  sku: sku
  tags: tags
}

output ID string = aks.id
output name string = aks.name

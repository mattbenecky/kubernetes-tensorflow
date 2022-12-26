targetScope = 'subscription'
// Resource Provider Prerequisites:
// Microsoft.ContainerService
// Microsoft.OperationalInsights
// Microsoft.OperationsManagement
// Microsoft.Dashboard

// ----------
// PARAMETERS
// ----------

param name string
param location string = deployment().location

@description('ISO 8601 format datetime when the application, workload, or service was first deployed.')
param startDate string = dateTimeAdd(utcNow(),'-PT5H','G')

@allowed(['Dev','Prod','QA','Stage','Test'])
@description('Deployment environment of the application, workload, or service.')
param env string

@secure()
param adminGroupID string

@secure()
param grafanaGroupID string

@description('When creating Hub VNet, you must specify a custom private IP address space using public and private (RFC 1918) addresses.')
param vnetDMZAddressSpace object

@description('Subnets to segment Hub VNet into one or more sub-networks and allocate a portion of the address space to each subnet.')
param vnetDMZSubnets array

@description('When creating AKS VNet, you must specify a custom private IP address space using public and private (RFC 1918) addresses.')
param vnetAKSAddressSpace object

// Array of subnets for AKS VNet provided in parameters JSON file
@description('Subnets to segment AKS VNet into one or more sub-networks and allocate a portion of the address space to each subnet.')
param vnetAKSSubnets array

// ---------
// VARIABLES
// ---------

var tags = {
  Env: env
  StartDate: startDate
}

// ---------
// RESOURCES
// ---------

// Azure Kubernetes Service
module aks 'modules/aks.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'AzureKubernetesService'
  params: {
    adminGroupID: adminGroupID
    apiServerSubnetID: vnetAKS.outputs.subnets[0].id
    name: '${name}-${env}'
    location: location
    privateDNSZoneID: dnsZoneAKS.outputs.ID
    tags: tags
    userAssignedID: idAKS.outputs.userAssignedID
    vnetSubnetID: vnetAKS.outputs.subnets[2].id
    workspaceID: log.outputs.workspaceID
  }
}

// Container Registry
module cr 'modules/cr.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'ContainerRegistry'
  params: {
    location: location
  }
}

// Private DNS Zone for Container Registry
module dnsZoneCR 'modules/dnszone.bicep' = {
  dependsOn: [roleDNSZoneContributor,roleNetworkContributor]
  scope: rg
  // Linked Deployment Name
  name: 'PrivateDNSZoneCR'
  params: {
    privateDNSZoneName: 'privatelink.azurecr.io'
  }
}

// Private DNS Zone for AKS Cluster
module dnsZoneAKS 'modules/dnszone.bicep' = {
  dependsOn: [roleDNSZoneContributor,roleNetworkContributor]
  scope: rg
  // Linked Deployment Name
  name: 'PrivateDNSZoneAKS'
  params: {
    privateDNSZoneName: 'privatelink.${location}.azmk8s.io'
  }
}

// Private DNS Zone Group to link Container Registry Private DNS Zone to Container Registry Private Endpoint
module dnsZoneGroup 'modules/dnsgroup.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'DNSZoneGroup'
  params: {
    privateDNSZoneID: dnsZoneCR.outputs.ID
    privateEndpointName: pepCR.outputs.name
  }
}

// Azure Managed Grafana analytics and monitoring data visualization for application and infrastructure
module grafana 'modules/grafana.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'AzureManagedGrafana'
  params: {
    azureMonitorWorkspaceResourceId: monitor.outputs.ID
    location: location
    name: 'grafana-${name}-${env}'
    tags: tags
  }
}

// User-Assigned Managed Identity for AKS Cluster
module idAKS 'modules/id.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'UserAssignedIdentityAKS'
  // User Assigned Identity Parameter Names and Values
  params: {
    name: 'id-aks-${env}'
    location: location
  }
}

// Virtual network link to connect Container Registry Private DNS Zone to AKS VNet
module linkCR 'modules/link.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetworkLinkAKS'
  params: {
    prefix: 'link-CR'
    privateDNSZoneName: dnsZoneCR.outputs.name
    vnetID: vnetAKS.outputs.vnetID
  }
}

// Virtual network link to connect AKS Private DNS Zone to DMZ VNet
module linkDMZ 'modules/link.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetworkLinkDMZ'
  params: {
    prefix: 'link-DMZ'
    privateDNSZoneName: dnsZoneAKS.outputs.name
    vnetID: vnetDMZ.outputs.vnetID
  }
}

// Log Analytics workspace to collect observability data (metrics, logs, distributed traces, and changes)
module log 'modules/log.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'LogAnalyticsWorkspace'
  params: {
    name: '${name}-${env}'
    location: location
    tags: tags
  }
}

// Azure Monitor workspace contains Prometheus metrics
module monitor 'modules/monitor.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'AzureMonitorWorkspace'
  params: {
    name: 'monitor-${name}-${env}'
    location: location
    tags: tags
  }
}

// Virtual network peering to connect AKS VNet to DMZ VNet
module peerAKS 'modules/peer.bicep' = {
  scope: rg
  name: 'VirtualNetworkPeeringAKS'
  params: {
    //name: '${vnetAKS.outputs.vnetName}/peerAKS'
    vnetName: vnetAKS.outputs.vnetName
    peerName: 'AKS-to-DMZ'
    remoteVirtualNetwork: vnetDMZ.outputs.ID
  }
}

// Virtual network peering to connect DMZ VNet to AKS VNet
module peerDMZ 'modules/peer.bicep' = {
  scope: rg
  name: 'VirtualNetworkPeeringDMZ'
  params: {
    //name: '${vnetDMZ.outputs.vnetName}/peer-DMZ'
    vnetName: vnetDMZ.outputs.vnetName
    peerName: 'DMZ-to-AKS'
    remoteVirtualNetwork: vnetAKS.outputs.ID
  }
}

// Private Endpoint for Container Registry
module pepCR 'modules/pep.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'PrivateEndpointCR'
  params: {
    location: location
    name: 'pep-${name}-${env}'
    privateLinkServiceConnections: [
      {
        name: 'PrivateEndpointConnectionCR'
        properties: {
          privateLinkServiceId: cr.outputs.ID
          groupIds: [
            'registry'
          ]
        }
      }
    ]
    snetID: vnetAKS.outputs.subnets[1]
  }
}

// Resource group is a container that holds related resources for an Azure solution
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${name}-${env}'
  location: location
  tags: tags
}

// Assign Private DNS Zone Contributor role to AKS identity to connect with AKS Private DNS Zone
module roleDNSZoneContributor 'modules/role.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'DNSZoneContributorRoleAssignment'
  // Parameter Names and Values
  params: {
    //name: guid(rg.id, idAMG.outputs.userAssignedIDobjectID, monitoringReaderRole.id)
    name: guid(subscription().id, 'b12aa53e-6015-4669-85d0-8515ebb3ae7f')
    principalId: idAKS.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','b12aa53e-6015-4669-85d0-8515ebb3ae7f')
  }
}

// Assign Monitoring Reader role to Grafana identity to read Azure Monitor Workspace
module roleMonitoringReader 'modules/role.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'MonitoringReaderRoleAssignment'
  // Parameter Names and Values
  params: {
    //name: guid(rg.id, idAMG.outputs.userAssignedIDobjectID, monitoringReaderRole.id)
    name: guid(subscription().id, '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
    principalId: grafana.outputs.principalID
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','43d0d8ad-25c7-4714-9337-8ba259a9fe05')
  }
}

// Assign Network Contributor role to AKS identity to manage AKS VNet (required to use AKS Private DNS Zone)
module roleNetworkContributor 'modules/role.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'NetworkContributorRoleAssignment'
  // Parameter Names and Values
  params: {
    //name: guid(rg.id, idAMG.outputs.userAssignedIDobjectID, monitoringReaderRole.id)
    name: guid(subscription().id, '4d97b98b-1d4f-4787-a291-c67834d212e7')
    principalId: idAKS.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}

// Assign Grafana Viewer role to Grafana Viewer Azure AD group
module roleGrafanaViewer 'modules/role.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'GrafanaViewerRoleAssignment'
  params: {
    name: guid(subscription().id, '60921a7e-fef1-4a43-9b16-a26c52ad4769')
    principalId: grafanaGroupID
    principalType: 'Group'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','60921a7e-fef1-4a43-9b16-a26c52ad4769')
  }
}

// Spoke virtual network that isolates Azure Kubernetes Service workload
module vnetAKS 'modules/vnet.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetwork-AKS'
  params: {
    name: 'aks-${name}-${env}'
    location: location
    tags: tags
    addressSpace: vnetAKSAddressSpace
    subnets: vnetAKSSubnets
  }
}

// Hub virtual network acts as a central point of connectivity to spoke virtual networks
module vnetDMZ 'modules/vnet.bicep' = {
  scope: rg
  // Linked Deployment Name
  name: 'VirtualNetwork-DMZ'
  params: {
    name: 'dmz-${name}-${env}'
    location: location
    tags: tags
    addressSpace: vnetDMZAddressSpace
    subnets: vnetDMZSubnets
  }
}

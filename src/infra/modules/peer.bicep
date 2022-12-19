// ----------
// PARAMETERS
// ----------

param vnetName string
param peerName string
param remoteVirtualNetwork object

// ----------
// VARIABLES
// ----------

var peering = {
  peeringState: 'Connected'
  peeringSyncLevel: 'FullyInSync'
  remoteVirtualNetwork: remoteVirtualNetwork
  allowVirtualNetworkAccess: true
  allowForwardedTraffic: true
  allowGatewayTransit: false
  useRemoteGateways: false
  doNotVerifyRemoteGateways: false
}

// ---------
// RESOURCES
// ---------

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01' = {
  // ${ParentVNetName}/PeeringName
  name: '${vnetName}/${peerName}'
  properties: {
    peeringState: peering.peeringState
    peeringSyncLevel: peering.peeringSyncLevel
    remoteVirtualNetwork: peering.remoteVirtualNetwork
    allowVirtualNetworkAccess: peering.allowVirtualNetworkAccess
    allowForwardedTraffic: peering.allowForwardedTraffic
    allowGatewayTransit: peering.allowGatewayTransit
    useRemoteGateways: peering.useRemoteGateways
    doNotVerifyRemoteGateways: peering.doNotVerifyRemoteGateways
  }
}

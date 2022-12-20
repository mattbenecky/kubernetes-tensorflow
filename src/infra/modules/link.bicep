param privateDNSZoneName string
param vnetID string
param prefix string

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  // ${ParentPrivateDNSZoneName}/VNetLinkName
  name: '${privateDNSZoneName}/${prefix}-${privateDNSZoneName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetID
    }
  }
}

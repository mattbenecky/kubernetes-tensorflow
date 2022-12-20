param privateDNSZoneName string

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
}

output name string = dnsZone.name
output ID string = dnsZone.id

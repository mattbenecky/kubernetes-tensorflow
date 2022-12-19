param name string
param location string = resourceGroup().location

// ---------
// RESOURCES
// ---------

resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: name
  location: location
 }

 output userAssignedID string = id.id
 output principalId string = id.properties.principalId
 
 output ID object = {
  id: id.id
}

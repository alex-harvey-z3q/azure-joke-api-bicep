@description('Globally unique Storage Account name.')
@minLength(3)
@maxLength(24)
param name string

@description('Azure region for the Storage Account.')
param location string

@description('Tags applied to the Storage Account.')
param tags object

// Microsoft.Storage/storageAccounts is the resource type. The API version fixes
// the contract Bicep uses when it validates and builds this resource.
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

output id string = storageAccount.id
output name string = storageAccount.name

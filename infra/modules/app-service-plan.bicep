@description('Name of the App Service Plan.')
param name string

@description('Azure region for the App Service Plan.')
param location string

@description('App Service Plan SKU, for example B1, S1, or P0v3.')
param skuName string

@description('Tags applied to the App Service Plan.')
param tags object

// A Bicep resource declaration starts with a symbolic name, then a resource
// type and API version. Microsoft.Web/serverfarms is the App Service Plan type.
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Module outputs expose only the values the parent template needs.
output id string = plan.id
output name string = plan.name

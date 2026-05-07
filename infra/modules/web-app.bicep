@description('Name of the Linux Web App.')
param name string

@description('Azure region for the Linux Web App.')
param location string

@description('Resource ID of the App Service Plan that will host this web app.')
param appServicePlanId string

@description('Node.js Linux runtime stack, for example NODE|20-lts.')
param nodeVersion string

@description('Application settings exposed as environment variables.')
param appSettings object

@description('Tags applied to the Web App.')
param tags object

// Microsoft.Web/sites is the App Service Web App resource type. The API version
// is part of the Azure Resource Manager schema used for this deployment.
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: nodeVersion
      alwaysOn: true
      appCommandLine: 'npm start'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        for settingName in items(appSettings): {
          name: settingName.key
          value: string(settingName.value)
        }
      ]
    }
  }
}

output id string = webApp.id
output name string = webApp.name
output defaultHostName string = webApp.properties.defaultHostName

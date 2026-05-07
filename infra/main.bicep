targetScope = 'resourceGroup'

// Bicep does not create a Terraform-style state file. Azure Resource Manager
// keeps the live resource state for this resource group, and each deployment
// submits a desired ARM template to Azure.

@description('Short project name used in Azure resource names.')
param projectName string = 'jokeapi'

@description('Deployment environment name. This is passed to the web app as APP_ENV.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Linux App Service Plan SKU. B1 is interview-demo friendly and supports Always On.')
param appServicePlanSku string = 'B1'

@description('Node.js runtime stack for the Linux Web App.')
param nodeVersion string = 'NODE|20-lts'

@description('Tags applied to all resources created by this deployment.')
param tags object = {
  project: 'azure-joke-api-bicep'
  environment: environment
  purpose: 'bicep-learning'
}

// Variables are local expressions. They keep naming consistent without
// requiring callers to pass every derived value.
var namePrefix = '${projectName}-${environment}'
var uniqueSuffix = uniqueString(resourceGroup().id)
var webAppName = '${namePrefix}-${uniqueSuffix}-web'
var appServicePlanName = '${namePrefix}-asp'

// Storage account names must be globally unique, lowercase, and 3-24 chars.
// uniqueString(resourceGroup().id) makes the name stable for this resource group.
var storageAccountName = toLower('${projectName}${environment}${uniqueString(resourceGroup().id)}')

// Modules compile to ARM nested deployments. Each module owns a small part of
// the infrastructure so learners can focus on one resource type at a time.
module storageAccount 'modules/storage-account.bicep' = {
  name: 'storage-account'
  params: {
    name: storageAccountName
    location: location
    tags: tags
  }
}

module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'app-service-plan'
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
    tags: tags
  }
}

module webApp 'modules/web-app.bicep' = {
  name: 'web-app'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    nodeVersion: nodeVersion
    appSettings: {
      APP_NAME: 'azure-joke-api-bicep'
      APP_ENV: environment
      STORAGE_ACCOUNT_NAME: storageAccount.outputs.name
    }
    tags: tags
  }
}

// These references create implicit dependencies. Bicep knows the web app needs
// the plan output and storage output before it can deploy, so no dependsOn is
// required here.
output appServicePlanId string = appServicePlan.outputs.id
output storageAccountName string = storageAccount.outputs.name
output webAppName string = webApp.outputs.name
output webAppDefaultHostName string = webApp.outputs.defaultHostName
output healthUrl string = 'https://${webApp.outputs.defaultHostName}/health'

# Azure Joke API Bicep

A small Node.js + Express Joke API deployed to Azure App Service with modular Bicep. The project is intentionally simple so it works well as a Bicep learning and interview-demo project.

## API

| Route | Response |
| --- | --- |
| `GET /health` | `{ "status": "ok" }` |
| `GET /joke` | A random hardcoded joke from memory |
| `GET /metadata` | App name, environment, hostname, and current timestamp |

Run locally:

```bash
npm install
npm start
```

Then open:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/joke
curl http://localhost:3000/metadata
```

## Architecture

```text
Azure Resource Group
├── App Service Plan (Linux)
├── App Service Web App (Node.js)
└── Storage Account
```

The Storage Account is included to demonstrate provisioning an additional Azure resource and passing its name into the app with an app setting. The app does not use a database.

## Bicep Structure

```text
infra/
├── main.bicep
└── modules/
    ├── app-service-plan.bicep
    ├── storage-account.bicep
    └── web-app.bicep
```

`main.bicep` is the entry point. It declares parameters, variables, module instances, and outputs.

Each module owns one resource area:

| Module | Azure resource |
| --- | --- |
| `app-service-plan.bicep` | `Microsoft.Web/serverfarms` |
| `web-app.bicep` | `Microsoft.Web/sites` |
| `storage-account.bicep` | `Microsoft.Storage/storageAccounts` |

## Bicep Concepts In This Project

Resources use a type and API version, such as:

```bicep
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  ...
}
```

The resource type identifies what Azure creates. The API version defines the Azure Resource Manager schema Bicep validates and builds against.

Parameters let callers customize the deployment:

```bicep
param environment string = 'dev'
param location string = resourceGroup().location
```

Variables keep derived values readable:

```bicep
var namePrefix = '${projectName}-${environment}'
```

Outputs return useful deployment results:

```bicep
output healthUrl string = 'https://${webApp.outputs.defaultHostName}/health'
```

Module outputs connect modules together. For example, `main.bicep` passes the App Service Plan resource ID into the Web App module:

```bicep
appServicePlanId: appServicePlan.outputs.id
```

That reference creates an implicit dependency. Bicep understands the Web App depends on the App Service Plan output, so a manual `dependsOn` is not needed.

## Why There Is No Terraform-Style State File

Bicep deploys through Azure Resource Manager. Azure Resource Manager stores the current state of deployed Azure resources in Azure itself. Bicep describes the desired template for a deployment, then ARM compares and applies changes inside the target scope.

Terraform usually keeps a separate state file because it manages resources across providers and needs its own state model. Bicep does not create a local `.tfstate` equivalent for Azure resources.

## Build The Bicep Template

From the project root:

```bash
az bicep build --file infra/main.bicep
```

This produces `infra/main.json`, an ARM template generated from the Bicep files.

## Deploy Infrastructure

Choose names that are unique enough for your subscription:

```bash
RESOURCE_GROUP=rg-joke-api-bicep-dev
LOCATION=australiaeast
PROJECT_NAME=jokeapi
ENVIRONMENT=dev
```

Create the resource group:

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"
```

Deploy the Bicep template:

```bash
az deployment group create \
  --name joke-api-infra \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters projectName="$PROJECT_NAME" environment="$ENVIRONMENT" location="$LOCATION"
```

Get the deployed web app name:

```bash
WEB_APP_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name joke-api-infra \
  --query properties.outputs.webAppName.value \
  --output tsv)
```

## Deploy The App Code

Create a zip package that excludes local dependencies and generated files:

```bash
zip -r app.zip package.json src -x "node_modules/*"
```

Deploy the zip to App Service:

```bash
az webapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_APP_NAME" \
  --src app.zip
```

Check the health endpoint:

```bash
HOSTNAME=$(az webapp show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEB_APP_NAME" \
  --query defaultHostName \
  --output tsv)

curl "https://$HOSTNAME/health"
curl "https://$HOSTNAME/joke"
curl "https://$HOSTNAME/metadata"
```

## Modules And ARM Nested Deployments

Bicep modules compile to nested deployments in the generated ARM template. This means each `module` block in `main.bicep` becomes a `Microsoft.Resources/deployments` resource in ARM JSON.

Modules are a Bicep authoring feature. They help organize code, pass parameters between files, and expose outputs. Azure Resource Manager still receives a normal ARM deployment.

## Bicep vs Terraform vs CloudFormation

| Topic | Bicep | Terraform | CloudFormation |
| --- | --- | --- | --- |
| Main target | Azure | Multi-cloud and many providers | AWS |
| State | Azure Resource Manager state | Terraform state file or remote backend | AWS CloudFormation stack state |
| Language | Bicep DSL compiled to ARM JSON | HCL | YAML or JSON |
| Modules | Compile to ARM nested deployments | Reusable Terraform modules | Nested stacks or modules |
| Provider setup | Uses Azure Resource Manager | Requires provider plugins | Built into AWS |

Bicep feels closest to writing Azure-native infrastructure code. Terraform is broader and provider-based. CloudFormation is AWS-native and stack-based.

## Cleanup

Delete the resource group and everything inside it:

```bash
az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait
```

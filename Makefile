SHELL := /bin/bash

RESOURCE_GROUP ?= rg-joke-api-bicep-dev
LOCATION ?= australiaeast
PROJECT_NAME ?= jokeapi
ENVIRONMENT ?= dev
DEPLOYMENT_NAME ?= joke-api-infra
ZIP_FILE ?= app.zip

.PHONY: help install start check bicep-build bicep-lint lint package group-create deploy-infra webapp-name deploy-app smoke clean-local destroy

help:
	@printf "Targets:\n"
	@printf "  make install       Install Node dependencies with npm ci\n"
	@printf "  make start         Run the API locally\n"
	@printf "  make lint          Run Node check, Bicep lint, and Bicep build\n"
	@printf "  make package       Create $(ZIP_FILE) for App Service zip deployment\n"
	@printf "  make group-create  Create the Azure resource group\n"
	@printf "  make deploy-infra  Deploy the Bicep infrastructure\n"
	@printf "  make deploy-app    Zip and deploy the Node app to the Web App\n"
	@printf "  make smoke         Call /health, /joke, and /metadata on the deployed app\n"
	@printf "  make destroy       Delete the Azure resource group\n"

install:
	npm ci

start:
	npm start

check:
	npm run check

bicep-build:
	az bicep build --file infra/main.bicep

bicep-lint:
	az bicep lint --file infra/main.bicep

lint: check bicep-lint bicep-build

package:
	rm -f $(ZIP_FILE)
	zip -r $(ZIP_FILE) package.json package-lock.json src -x "node_modules/*"

group-create:
	az group create \
		--name "$(RESOURCE_GROUP)" \
		--location "$(LOCATION)"

deploy-infra:
	az deployment group create \
		--name "$(DEPLOYMENT_NAME)" \
		--resource-group "$(RESOURCE_GROUP)" \
		--template-file infra/main.bicep \
		--parameters projectName="$(PROJECT_NAME)" environment="$(ENVIRONMENT)" location="$(LOCATION)"

webapp-name:
	@az deployment group show \
		--resource-group "$(RESOURCE_GROUP)" \
		--name "$(DEPLOYMENT_NAME)" \
		--query properties.outputs.webAppName.value \
		--output tsv

deploy-app: package
	WEB_APP_NAME="$${WEB_APP_NAME:-$$(az deployment group show --resource-group "$(RESOURCE_GROUP)" --name "$(DEPLOYMENT_NAME)" --query properties.outputs.webAppName.value --output tsv)}"; \
	az webapp deployment source config-zip \
		--resource-group "$(RESOURCE_GROUP)" \
		--name "$${WEB_APP_NAME}" \
		--src "$(ZIP_FILE)"

smoke:
	WEB_APP_NAME="$${WEB_APP_NAME:-$$(az deployment group show --resource-group "$(RESOURCE_GROUP)" --name "$(DEPLOYMENT_NAME)" --query properties.outputs.webAppName.value --output tsv)}"; \
	HOSTNAME="$$(az webapp show --resource-group "$(RESOURCE_GROUP)" --name "$${WEB_APP_NAME}" --query defaultHostName --output tsv)"; \
	curl "https://$${HOSTNAME}/health"; \
	printf "\n"; \
	curl "https://$${HOSTNAME}/joke"; \
	printf "\n"; \
	curl "https://$${HOSTNAME}/metadata"; \
	printf "\n"

clean-local:
	rm -f $(ZIP_FILE) infra/main.json

destroy:
	az group delete \
		--name "$(RESOURCE_GROUP)" \
		--yes \
		--no-wait

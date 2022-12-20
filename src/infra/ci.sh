#!/bin/sh

read -p "Enter GitHub username: " GITHUB_USER

# Register EnableAPIServerVnetIntegrationPreview feature flag on subscription
az feature register --namespace "Microsoft.ContainerService" --name "EnableAPIServerVnetIntegrationPreview"
# Refresh registration of Microsoft.ContainerService resource provider
az provider register --namespace Microsoft.ContainerService

# Install extensions automatically by enabling dynamic install without a prompt
az config set extension.use_dynamic_install=yes_without_prompt
SIGNED_IN_USER_ID=$(az ad signed-in-user show --query "[id]" | tr -d '[]" \n')
SUBSCRIPTION_ID=$(az account show --query "[id]" | tr -d '[]" \n')
TENANT_ID=$(az account show --query "[tenantId]" | tr -d '[]" \n')
SUBSCRIPTION_SCOPE=$(az account subscription show --id $SUBSCRIPTION_ID --query "[id]" | tr -d '[]" \n')

az ad group create --display-name "CI Admin" --mail-nickname "Admin"
ADMIN_GROUP_ID=$(az ad group show -g "CI Admin" --query "[id]" | tr -d '[]" \n')

az ad app create --display-name "Continuous Integration Principal"
CI_APP_OBJECT_ID=$(az ad app list --display-name "Continuous Integration Principal" --query "[0].[id]" | tr -d '[]" \n')
CI_APP_ID=$(az ad app list --display-name "Continuous Integration Principal" --query "[0].[appId]" | tr -d '[]" \n')
az ad app federated-credential create \
   --id $CI_APP_OBJECT_ID \
   --parameters "{\"name\":\"id-ci-principal\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${GITHUB_USER}/kubernetes-tensorflow:environment:Dev\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

az ad sp create --id $CI_APP_OBJECT_ID
CI_SP_OBJECT_ID=$(az ad sp list --display-name "Continuous Integration Principal" --query "[0].[id]" | tr -d '[]" \n')
az role assignment create \
  --assignee-object-id $CI_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role Contributor \
  --scope $SUBSCRIPTION_SCOPE

az role assignment create \
  --assignee-object-id $CI_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $CI_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Role Based Access Control Administrator (Preview)" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $CI_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Private DNS Zone Contributor" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $CI_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Network Contributor" \
  --scope $SUBSCRIPTION_SCOPE

echo -e "\nClick Settings -> Environments"
echo -e "\n+ New Environment: Dev"
echo -e "\nAdd the following GitHub Secrets:"
echo "════════════════════════════════════════════════════════════════════════"
echo "Name: CI_CLIENT_ID         Value:" $DEPLOYMENT_APP_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: CI_TENANT_ID         Value:" $TENANT_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: CI_SUBSCRIPTION_ID   Value:" $SUBSCRIPTION_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: CI_ADMIN_GROUP_ID    Value:" $ADMIN_GROUP_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: CI_GRAFANA_GROUP_ID  Value:" $ADMIN_GROUP_ID
echo "────────────────────────────────────────────────────────────────────────"

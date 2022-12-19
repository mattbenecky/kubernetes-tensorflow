#!/bin/sh
#register Microsoft.ManagedIdentity

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

az ad group create --display-name "AKS Cluster Admin" --mail-nickname "Admin"
az ad group create --display-name "Grafana Viewer" --mail-nickname "Grafana"
ADMIN_GROUP_ID=$(az ad group show -g "AKS Cluster Admin" --query "[id]" | tr -d '[]" \n')
GRAFANA_GROUP_ID=$(az ad group show -g "Grafana Viewer" --query "[id]" | tr -d '[]" \n')
az ad group member add -g $ADMIN_GROUP_ID --member-id $SIGNED_IN_USER_ID
az ad group member add -g $GRAFANA_GROUP_ID --member-id $SIGNED_IN_USER_ID

az ad app create --display-name "Deployment Principal"
DEPLOYMENT_APP_OBJECT_ID=$(az ad app list --display-name "Deployment Principal" --query "[0].[id]" | tr -d '[]" \n')
DEPLOYMENT_APP_ID=$(az ad app list --display-name "Deployment Principal" --query "[0].[appId]" | tr -d '[]" \n')
az ad app federated-credential create \
   --id $DEPLOYMENT_APP_OBJECT_ID \
   --parameters "{\"name\":\"id-deployment-principal\",\"issuer\":\"https://token.actions.githubusercontent.com\",\"subject\":\"repo:${GITHUB_USER}/kubernetes-tensorflow:environment:Dev\",\"audiences\":[\"api://AzureADTokenExchange\"]}"

az ad sp create --id $DEPLOYMENT_APP_OBJECT_ID
DEPLOYMENT_SP_OBJECT_ID=$(az ad sp list --display-name "Deployment Principal" --query "[0].[id]" | tr -d '[]" \n')
az role assignment create \
  --assignee-object-id $DEPLOYMENT_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role Contributor \
  --scope $SUBSCRIPTION_SCOPE

az role assignment create \
  --assignee-object-id $DEPLOYMENT_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $DEPLOYMENT_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Role Based Access Control Administrator (Preview)" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $DEPLOYMENT_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Private DNS Zone Contributor" \
  --scope $SUBSCRIPTION_SCOPE
az role assignment create \
  --assignee-object-id $DEPLOYMENT_SP_OBJECT_ID \
  --assignee-principal-type "ServicePrincipal" \
  --role "Network Contributor" \
  --scope $SUBSCRIPTION_SCOPE
az ad group member add -g $ADMIN_GROUP_ID --member-id $DEPLOYMENT_SP_OBJECT_ID

az group create -l "eastus" -g "rg-tensorflow-Dev"
az identity create -g "rg-tensorflow-Dev" -n "id-script-Dev"
SCRIPT_PRINCIPAL_ID=$(az identity show -g "rg-tensorflow-Dev" -n "id-script-Dev" --query "[principalId]" | tr -d '[]" \n')

az role assignment create \
   --assignee-object-id $SCRIPT_PRINCIPAL_ID \
   --assignee-principal-type "ServicePrincipal" \
   --role Contributor \
   --scope $SUBSCRIPTION_SCOPE
#  --assignee $SCRIPT_PRINCIPAL_ID \ Replication Latency Error -> Use assignee-object-id

echo -e "\nClick Settings -> Environments"
echo -e "\nNew Environment = ""Dev"""
echo -e "\nAdd the following GitHub Secrets:"
echo "════════════════════════════════════════════════════════════════════════"
echo "Name: CLIENT_ID         Value:" $DEPLOYMENT_APP_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: TENANT_ID         Value:" $TENANT_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: SUBSCRIPTION_ID   Value:" $SUBSCRIPTION_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: ADMIN_GROUP_ID    Value:" $ADMIN_GROUP_ID
echo "────────────────────────────────────────────────────────────────────────"
echo "Name: GRAFANA_GROUP_ID  Value:" $GRAFANA_GROUP_ID
echo "────────────────────────────────────────────────────────────────────────"

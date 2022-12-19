#!/bin/sh

# Required Permissions:
#Microsoft.Authorization/elevateAccess/action

# Delete Azure AD Groups
az ad group delete -g "AKS Cluster Admin"
az ad group delete -g "Grafana Viewer"

# Delete Deployment Principal App Registration
DEPLOYMENT_OBJECT_ID=$(az ad app list --display-name "Deployment Principal" --query "[0].[id]" | tr -d '[]" \n')
az ad app delete --id $DEPLOYMENT_OBJECT_ID
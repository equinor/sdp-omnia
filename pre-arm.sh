#!/bin/bash
# This script bootstraps a kubernetes cluster on Azure (AKS) with helm,
# It also configures the client to run kubectl commands on the cluster (.kube/config)
# All variables should be defined in a file called ".env"
set -e

function service_principal_exist {
    az ad sp show --id http://$1 --query objectId -o tsv > /dev/null 2>&1
}

# Create service principals and store the credentials in Azure Key Vault
SP_NAME="${AZ_GROUP}-dns-sp"
echo
if ! service_principal_exist $SP_NAME; then
    echo " Service principal $SP_NAME does not exist, creating it.."
    SP_PASSWORD=$(az ad sp create-for-rbac --skip-assignment --name $SP_NAME --query password -o tsv)
    az keyvault secret set --name "$SP_NAME-password" --vault-name SDPVault --value $SP_PASSWORD > /dev/null
    SP_OBJECT_ID=$(az ad sp show --id http://$SP_NAME --query objectId -o tsv)
    az keyvault secret set --name "$SP_NAME-object-id" --vault-name SDPVault --value $SP_OBJECT_ID > /dev/null
else
    echo " Service principal for dns zone already exists..."
fi

SP_NAME="${AZ_GROUP}-aks-sp"
echo
if ! service_principal_exist $SP_NAME; then
    echo " Service principal $SP_NAME does not exist, creating it.."
    SP_PASSWORD=$(az ad sp create-for-rbac --skip-assignment --name $SP_NAME --query password -o tsv)
    az keyvault secret set --name "$SP_NAME-password" --vault-name SDPVault --value $SP_PASSWORD > /dev/null
    SP_APP_ID=$(az ad sp show --id http://$SP_NAME --query appId -o tsv)
    az keyvault secret set --name "$SP_NAME-app-id" --vault-name SDPVault --value $SP_APP_ID > /dev/null
else
    echo " Service principal for aks already exists..."
fi

echo
echo " If the ARM deployment fails with 'service principal does not exist' run the script again.."
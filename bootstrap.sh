#!/bin/bash
# This script bootstraps a kubernetes cluster on Azure (AKS) with helm,
# It also configures the client to run kubectl commands on the cluster (.kube/config)
# All variables should be defined in a file called ".env"

source .env
set -e

# Check for prerequisites binaries
echo
echo " Check for neccesary executables"
hash az || { echo "Error: Azure-CLI not found in PATH. Exiting...";  exit 1; }
hash kubectl || { echo "Error: kubectl not found in PATH. Exiting..."; exit 1; }
hash helm || { echo "Error: helm not found in PATH. Exiting..."; exit 1; }

# Login to Azure if not already logged inn
echo
echo " Logging you in to Azure if not already logged in"
az account show > /dev/null || az login > /dev/null

# Set Azure-CLI config
echo
echo " Setting subscription (${AZ_SUBSCRIPTION})"
az account set --subscription "$AZ_SUBSCRIPTION" > /dev/null

source ./pre-arm.sh

echo
echo " Deploying arm templates with parameter file ./arm-templates/${ENVIRONMENT}/deploy-arm.parameters.json"

az deployment create --name "$AZ_GROUP" --location "$AZ_LOCATION" --template-file ./arm-templates/base/deploy-arm.json --parameters @./arm-templates/${ENVIRONMENT}/deploy-arm.parameters.json > /dev/null

echo
echo " Set default resource group (${AZ_GROUP})"
az configure --defaults group=$AZ_GROUP > /dev/null

# Register the client in the kubernetes cluster and creates ~/.kube directory with keys and kubectl connection info
echo
echo " Getting Kubernetes cluster details"
az aks get-credentials --name "${AZ_GROUP}-k8s"

source ./post-arm.sh
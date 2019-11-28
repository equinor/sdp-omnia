#!/bin/bash

# Create the helm service account
echo
echo " Creating Helm Tiller service account"
kubectl create -f manifests/tiller-service-account.yml > /dev/null || true

# Deploys the helm service on the cluster
echo
echo " Initialising Helm"
helm init --service-account tiller

echo
echo " Creating namespaces"
kubectl create -f manifests/namespaces.yaml > /dev/null || true

#
# Create external dns secret
#

# Fetch Azure ID's
AZ_SUBSCRIPTION_ID=$(az account show --query "id"  -o tsv)
AZ_TENANT_ID=$(az account show --query "tenantId"  -o tsv)
AZ_DNS_SP_NAME="${AZ_GROUP}-dns-sp"
AZ_DNS_SP_PASSWORD=$(az keyvault secret show --name "${AZ_DNS_SP_NAME}-password" --vault-name SDPVault --query value -o tsv)
AZ_DNS_SP_ID=$(az keyvault secret show --name "${AZ_DNS_SP_NAME}-app-id" --vault-name SDPVault --query value -o tsv)

# Use custom configuration file
echo
echo " Creating azure.json file with DNS service principal information"
cat << EOF > azure.json
{
  "tenantId": "$AZ_TENANT_ID",
  "subscriptionId": "$AZ_SUBSCRIPTION_ID",
  "aadClientId": "$AZ_DNS_SP_ID",
  "aadClientSecret": "$AZ_DNS_SP_PASSWORD",
  "resourceGroup": "$AZ_DNS_GROUP"
}
EOF

# Create a secret so that external-dns can connect to the DNS zone
echo
echo " Creating Kubernetes secret (infrastructure/azure-dns-config-file) from azure.json file"
kubectl create secret generic azure-dns-config-file --from-file=azure.json --namespace external-dns > /dev/null || true
rm -f azure.json

#
# Create sealed secrets secret
#

az keyvault secret show --name "sealed-secrets-key" --vault-name SDPVault --query value -o tsv > tmp.key
az keyvault secret show --name "sealed-secrets-cert" --vault-name SDPVault --query value -o tsv > tmp.crt
kubectl create secret tls -n sealed-secrets sealed-secret-custom-key --cert=tmp.crt --key=tmp.key > /dev/null || true
rm -f tmp.key tmp.crt

function key_exists {
  az keyvault secret show --name $1 --vault-name SDPVault > /dev/null
}

# Create ssh-key
FLUX_KEY_NAME="${AZ_GROUP}-flux-key"
if ! key_exists $FLUX_KEY_NAME; then
    echo
    echo " Creating flux ssh key"
    ssh-keygen -q -N "" -C "flux@${ENVIRONMENT}.sdpaks.equinor.com" -f ./identity
    az keyvault secret set --vault-name SDPVault -n $FLUX_KEY_NAME -f './identity' > /dev/null
    echo
    echo "Add flux public key to flux git repo:"
    echo
    cat identity.pub
    rm -f identity identity.pub
fi

FLUX_KEY="$(az keyvault secret show --name "$FLUX_KEY_NAME" --vault-name SDPVault --query value -o tsv)"

kubectl -n flux create secret generic flux-ssh --from-literal=identity="$FLUX_KEY" > /dev/null || true

# Add flux repo to helm
echo
echo " Adding fluxcd/flux repository to Helm"
helm repo add fluxcd https://fluxcd.github.io/flux > /dev/null

# Install flux with helmoperator
echo
echo " Installing or upgrading Flux with Helm operator in the infrastructure namespace"
helm upgrade --install flux \
    --namespace flux \
    --set rbac.create=true \
    --set helmOperator.create=true \
    --set helmOperator.createCRD=true \
    --set git.url="$FLUX_GITOPS_REPO" \
    --set git.branch=$FLUX_GITOPS_BRANCH \
    --set git.path=$FLUX_GITOPS_PATH \
    --set additionalArgs={--manifest-generation=true} \
    --set git.secretName="flux-ssh" \
    fluxcd/flux > /dev/null

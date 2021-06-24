#! /bin/bash
# This script needs to be run after the ARM-templates have been deployed.
# It's job is to create the basic kubernetes services that are needed for our GitOps to work (mainly Helm and Flux)
source .env

echo $ENVIRONMENT

# Ensure correct cluster context
az account set --subscription "${AZ_SUBSCRIPTION}"
#az aks get-credentials -g "${AZ_GROUP}"  -n "${AZ_GROUP}-k8s" --overwrite-existing

echo
echo " Creating namespaces"
kubectl apply -f manifests/namespaces.yaml > /dev/null || true

echo " Creating Custom storageclasses"
kubectl apply -f manifests/storageclasses.yaml > /dev/null || true

# Fetch Azure ID's from Keyvault (Created in pre-arm.sh)
AZ_SUBSCRIPTION_ID=$(az account show --query "id"  -o tsv)
AZ_TENANT_ID=$(az account show --query "tenantId"  -o tsv)
AZ_DNS_SP_NAME="${AZ_GROUP}-dns-sp"
AZ_DNS_SP_PASSWORD=$(az keyvault secret show --name "${AZ_DNS_SP_NAME}-password" --vault-name SDPVault --query value -o tsv)
AZ_DNS_SP_ID=$(az keyvault secret show --name "${AZ_DNS_SP_NAME}-app-id" --vault-name SDPVault --query value -o tsv)
AZ_BACKUP_SP_NAME="sdpaks-common-velero-sp"
AZ_BACKUP_SP_PASSWORD=$(az keyvault secret show --name "${AZ_BACKUP_SP_NAME}-password" --vault-name SDPVault --query value -o tsv)
AZ_BACKUP_SP_ID=$(az keyvault secret show --name "${AZ_BACKUP_SP_NAME}-app-id" --vault-name SDPVault --query value -o tsv)
AZ_CLUSTER_GROUP=$(az aks show --resource-group $AZ_GROUP --name "${AZ_GROUP}-k8s" --query nodeResourceGroup -o tsv)
POSTGRES_USERNAME=$(az keyvault secret show --name "${AZ_GROUP}-psql-username" --vault-name SDPVault --query value -o tsv)
POSTGRES_PASSWORD=$(az keyvault secret show --name "${AZ_GROUP}-psql-password" --vault-name SDPVault --query value -o tsv)

#
# Create external dns secret
#

# Use custom configuration file
echo
echo " Creating azure.json file with DNS service principal information"
cat << EOF > azure.json
{
  "tenantId": "$AZ_TENANT_ID",
  "subscriptionId": "$AZ_SUBSCRIPTION_ID",
  "aadClientId": "$AZ_DNS_SP_ID",
  "aadClientSecret": "$AZ_DNS_SP_PASSWORD",
  "resourceGroup": "k8s-infrastructure"
}
EOF

# Create a secret so that external-dns can connect to the DNS zone
echo
echo " Creating Kubernetes secret (external-dns/azure-dns-config-file) from azure.json file"
kubectl create secret generic azure-dns-config-file --from-file=azure.json -n external-dns --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true
rm -f azure.json

#
# Create sealed-secrets secret
#

az keyvault secret show --name "sealed-secrets-key" --vault-name SDPVault --query value -o tsv > tmp.key
az keyvault secret show --name "sealed-secrets-cert" --vault-name SDPVault --query value -o tsv > tmp.crt
kubectl create secret tls -n sealed-secrets sealed-secret-custom-key --cert=tmp.crt --key=tmp.key --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true
rm -f tmp.key tmp.crt
echo
echo " Remember to restart sealed-secret pod if it already exists to pick up custom keys"


function key_exists {
  az keyvault secret show --name $1 --vault-name SDPVault > /dev/null
}

# Add flux repo to helm
echo
echo " Adding fluxcd/flux repository to Helm"
helm repo add fluxcd https://charts.fluxcd.io > /dev/null

# Install Flux
echo
echo " Installing or upgrading Flux with Helm operator in the flux namespace"
helm upgrade --install flux --version 1.6.0 \
    --namespace flux \
    --set git.url="$FLUX_GITOPS_REPO" \
    --set git.branch="$FLUX_GITOPS_BRANCH" \
    --set git.path=$FLUX_GITOPS_PATH \
    --set manifestGeneration=true \
    fluxcd/flux > /dev/null


# Install Flux Helm Operator with Helm v3 support
# HelmRelease CRD first
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

helm upgrade -i helm-operator fluxcd/helm-operator --version 1.2.0  --wait \
    --namespace flux \
    --set git.ssh.secretName="flux-git-deploy" \
    --set helm.versions=v3

# Create cluster secret for velero - two format types needed due to bug with azure provider

echo
echo " Generating velero credentials..."

cat << EOF > cloud
AZURE_SUBSCRIPTION_ID=${AZ_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZ_TENANT_ID}
AZURE_CLIENT_ID=${AZ_BACKUP_SP_ID}
AZURE_CLIENT_SECRET=${AZ_BACKUP_SP_PASSWORD}
AZURE_RESOURCE_GROUP=${AZ_CLUSTER_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

kubectl create secret generic velero-credentials --from-file=cloud -n velero --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

# Create secret for gitlab to connect to postgresSQL
echo
echo " Generating secret for gitlab - external postgres.."
kubectl create secret generic gitlab-postgres-secret \
    --namespace gitlab \
    --from-literal username=${POSTGRES_USERNAME} \
    --from-literal password=${POSTGRES_PASSWORD} --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

# Create secrets for minio to connect to storage account (multiple needed)
echo
echo " Generating secrets for gitlab-minio..."

MINIO_STORAGE_NAME="sdpaks${ENVIRONMENT}minio"
MINIO_SECRET_KEY=$(az storage account keys list --resource-group sdpaks-"${ENVIRONMENT}"-gitlab-storage --account-name "$MINIO_STORAGE_NAME"  --query [0].value -o tsv)

kubectl create secret generic gitlab-minio-secret \
    --namespace gitlab \
    --from-literal accesskey=${MINIO_STORAGE_NAME} \
    --from-literal secretkey=${MINIO_SECRET_KEY} --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

rm -f azure.json

cat << EOF > connection
provider: AWS
region: us-east-1
aws_access_key_id: ${MINIO_STORAGE_NAME}
aws_secret_access_key: ${MINIO_SECRET_KEY}
aws_signature_version: 4
host: http://gitlab-minio.gitlab.svc.cluster.local:9000
endpoint: http://gitlab-minio.gitlab.svc.cluster.local:9000
path_style: true
EOF

kubectl create secret generic gitlab-rails-storage --from-file=connection -n gitlab --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

cat << EOF > config
azure:
  accountname: ${MINIO_STORAGE_NAME}
  accountkey: ${MINIO_SECRET_KEY}
  container: gitlab-registry-storage
redirect:
  disable: true
EOF

kubectl create secret generic registry-storage --from-file=config -n gitlab --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

cat << EOF > config
[default]
host_base = http://gitlab-minio.gitlab.svc.cluster.local:9000
host_bucket = http://gitlab-minio.gitlab.svc.cluster.local:9000
# Leave as default
bucket_location = us-east-1
use_https = false
access_key =  ${MINIO_STORAGE_NAME}
secret_key = ${MINIO_SECRET_KEY}

signature_v2 = False
EOF

kubectl create secret generic backup-storage-config --from-file=config -n gitlab --dry-run=client -o yaml | kubectl apply -f - > /dev/null || true

rm -f connection & rm -f azure.json  & rm -f cloud & rm -f config

echo " Script completed."

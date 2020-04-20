#! /bin/bash
# This script creates needs to run before deploying the ARM-templates.
# It will create any outside dependecies the the templates needs (mainly Service Accounts)
# All variables should be defined in a file called ".env"
set -e
source .env

function service_principal_exist {
    az ad sp show --id http://$1 --query objectId -o tsv > /dev/null 2>&1
}
function keyvault_secret_exist {
    az keyvault secret show --vault-name SDPVault -n $1 --query value -o tsv > /dev/null 2>&1
}

if ! keyvault_secret_exist "$AZ_GROUP-psql-username" || ! keyvault_secret_exist "$AZ_GROUP-psql-password"; then
    echo " PSQL account details for $ENVIRONMENT cluster does not exist, creating it.."
    az keyvault secret set --name "$AZ_GROUP-psql-username" --vault-name SDPVault --value $PSQL_USERNAME > /dev/null
    az keyvault secret set --name "$AZ_GROUP-psql-password" --vault-name SDPVault --value $PSQL_PASSWORD > /dev/null
else
    echo " PSQL account details already exists..."
fi

# Create service principals and store the credentials in Azure Key Vault
SP_NAME="${AZ_GROUP}-dns-sp"
echo
if ! service_principal_exist $SP_NAME; then
    echo " Service principal $SP_NAME does not exist, creating it.."
    SP_PASSWORD=$(az ad sp create-for-rbac --skip-assignment --name $SP_NAME --query password -o tsv)
    az keyvault secret set --name "$SP_NAME-password" --vault-name SDPVault --value $SP_PASSWORD > /dev/null
    SP_OBJECT_ID=$(az ad sp show --id http://$SP_NAME --query objectId -o tsv)
    az keyvault secret set --name "$SP_NAME-object-id" --vault-name SDPVault --value $SP_OBJECT_ID > /dev/null
    SP_APP_ID=$(az ad sp show --id http://$SP_NAME --query appId -o tsv)
    az keyvault secret set --name "$SP_NAME-app-id" --vault-name SDPVault --value $SP_APP_ID > /dev/null
else
    echo " Service principal for dns zone already exists..."
fi

SP_NAME="${AZ_GROUP}-aks-sp"
echo
if ! service_principal_exist $SP_NAME; then
    echo " Service principal $SP_NAME does not exist, creating it.."
    SP_PASSWORD=$(az ad sp create-for-rbac --skip-assignment --name $SP_NAME --query password -o tsv)
    az keyvault secret set --name "$SP_NAME-password" --vault-name SDPVault --value $SP_PASSWORD > /dev/null
    SP_OBJECT_ID=$(az ad sp show --id http://$SP_NAME --query objectId -o tsv)
    az keyvault secret set --name "$SP_NAME-object-id" --vault-name SDPVault --value $SP_OBJECT_ID > /dev/null
    SP_APP_ID=$(az ad sp show --id http://$SP_NAME --query appId -o tsv)
    az keyvault secret set --name "$SP_NAME-app-id" --vault-name SDPVault --value $SP_APP_ID > /dev/null
else
    echo " Service principal for aks already exists..."
fi

SP_NAME="sdpaks-common-velero-sp"
echo
if ! service_principal_exist $SP_NAME; then
    echo " Service principal $SP_NAME does not exist, creating it.."
    SP_PASSWORD=$(az ad sp create-for-rbac --skip-assignment --name $SP_NAME --query password -o tsv)
    az keyvault secret set --name "$SP_NAME-password" --vault-name SDPVault --value $SP_PASSWORD > /dev/null
    SP_OBJECT_ID=$(az ad sp show --id http://$SP_NAME --query objectId -o tsv)
    az keyvault secret set --name "$SP_NAME-object-id" --vault-name SDPVault --value $SP_OBJECT_ID > /dev/null
    SP_APP_ID=$(az ad sp show --id http://$SP_NAME --query appId -o tsv)
    az keyvault secret set --name "$SP_NAME-app-id" --vault-name SDPVault --value $SP_APP_ID > /dev/null
else
    echo " Service principal for aks already exists..."
fi

echo
echo " If the ARM deployment fails with 'service principal does not exist' run the script again.."

# Get existing reply urls for app registration
EXISTINGREGS=$(az ad app list --display-name 'SDP Team' --query [0].replyUrls -o tsv)

echo " Creating List of Reply Urls per environment (leave variable for prod cluster blank)..."
# Make sure there are no spaces at the end of each line!"
cat << EOF > newapplist.json
https://alertmanager.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://aware.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://gitlab.${PREFIX}sdpaks.equinor.com/users/auth/azure_oauth2/callback
https://grafana.${PREFIX}sdpaks.equinor.com/login/generic_oauth
https://kibana.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://monitor.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://prometheus.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://release-aware.${PREFIX}sdpaks.equinor.com/oauth2/callback
https://sdp-web.${PREFIX}sdpaks.equinor.com/oauth2/callback
EOF

# Sort and format list to newline format
echo
echo $EXISTINGREGS | tr ' ' '\n' | sort | tr '\n' ' ' | tr " " "\n" >  cat > existingregs.json

# Create differential list (requires sorted newline)
DIFFLIST=$(awk 'NR==FNR{a[$0]=1;next}!a[$0]' existingregs.json newapplist.json)
# Cleanup files
rm existingregs.json & rm newapplist.json

# Hardcoded object Id for 'SDP Team' (required)
# Important, no quotes around the below command! az cli requires space separated values
echo " Updating existing app registration with the following reply urls:"
az ad app update --add replyUrls ${DIFFLIST[@]} --id 3b014a2c-797d-43aa-a379-2344fc04b8cc

echo "${DIFFLIST[@]}"
echo
echo " Reply urls successfully added."

echo "$# arguments passed in."

if [[ $# -ne 33 ]] ; then
    echo 'Not all the required 33 arguments have not been passed in'
    exit 1
fi

for var in "$@"
do
    if [ -z ${var} ]; then 
        echo "One of the arguments is empty"
        exit 1
    else
        echo "$var"
    fi
done

hlfSubscription=${1}
servicePrincipalId=${2}
servicePrincipalKey=${3}
tenantId=${4}
hlfTDeployToolingRootFolder=${5}
hlfNetworkName=${6}
hlfPeerOrganization=${7}
hlfContextName=${8}
hlfChannelName=${9}
chainCodeUniqueName=${10}
chaincodeRootFolder=${11}
chainCodeFolder=${12}
chainCodeUniqueLabel=${13}
chainCodeVersion=${14}
chainCodeSequence=${15}
chainCodeComponentName=${16}
chainCodeUniqueNamespace=${17}
chainCodePort=${18}
chaincodeSupportEmail=${19}
dockerId=${20}
dockerUsername=${21}
dockerPwd=${22}
buildId=${23}
hlfPeerResourceGroup=${24}
hlfAksClusterPeer=${25}
chaincodeCertificateName=${26}
chaincodeCertificateKeyName=${27}
chaincodeCertificateCountry=${28}
chaincodeCertificateState=${29}
chaincodeCertificateLocality=${30}
chaincodeCertificateOrganisation=${31}
secretNamePrefix=${32}
keyVaultName=${33}

az login --service-principal --username $servicePrincipalId --password $servicePrincipalKey --tenant $tenantId  
az account set --subscription $hlfSubscription

export FABRIC_EXECUTABLE_PATH=$hlfTDeployToolingRootFolder/fabric-cli/bin/fabric

echo "Calling Fabric CLI network"
$FABRIC_EXECUTABLE_PATH network set $hlfNetworkName $hlfTDeployToolingRootFolder/setupFabricCli/$hlfPeerOrganization-config.yaml

echo "Setting Fabric CLI context"
export PEER_ORG_NAME=$hlfPeerOrganization
export PEER_ADMIN_IDENTITY="admin.$PEER_ORG_NAME"

$FABRIC_EXECUTABLE_PATH context set $hlfContextName --channel $hlfChannelName --network $hlfNetworkName --organization $hlfPeerOrganization --user $PEER_ADMIN_IDENTITY
$FABRIC_EXECUTABLE_PATH context use $hlfContextName

echo "Logging into AKS"
az aks get-credentials --resource-group $hlfPeerResourceGroup --name $hlfAksClusterPeer

echo "Starting chaincode operations"
cd $hlfTDeployToolingRootFolder/setupFabricCli/

echo "<START>=========$chainCodeUniqueName===========<START>"

INSTALL_LOCATION=$hlfTDeployToolingRootFolder/setupFabricCli/ 
CHIANCODE_SHARED_ROOT=$chaincodeRootFolder
CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION=$chainCodeFolder/deployment_artifacts          
CHAINCODE_NAME=$chainCodeUniqueName
CHIANCODE_LABEL=$chainCodeUniqueLabel
CHAINCODE_VERSION=$chainCodeVersion
CHAINCODE_SEQUENCE=$chainCodeSequence
COMP_NAME=$chainCodeComponentName
NAMESPACE=$chainCodeUniqueNamespace
ORG_NAME=$hlfPeerOrganization          
PORT=$chainCodePort       
SUPPORT_EMAIL=$chaincodeSupportEmail
MANIFEST_FILE_PATH=$chainCodeFolder/deployment_artifacts/deploy.yaml
ACR_NAME=$dockerId.azurecr.io
ACR_REPO_NAME=$chainCodeUniqueName
CHAINCODE_TAG=$chainCodeVersion.$chainCodeSequence-$buildId

cd $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION
mkdir crypto

# Save version info to a file
echo "Saving version information to file"
printf "$chainCodeVersion.$chainCodeSequence" > $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/version.txt
echo $(<$CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/version.txt)

# Check if chaincode meta data exists in keyvault
secretName=${secretNamePrefix}-${chainCodeUniqueName}
secret_exists=$(az keyvault secret list --vault-name ${keyVaultName} --query "contains([].id, 'https://${keyVaultName}.vault.azure.net/secrets/${secretName}')")
needs_updating=true

if [ "$secret_exists" = true ]; then
    echo "Secret '$secretName' exists! fetching..."
    secret_val=$(az keyvault secret show --vault-name $keyVaultName --name $secretName --query "value" -o tsv)

    if [ "$secret_val" = "$chainCodeVersion.$chainCodeSequence" ]; then
        # same version, so we can use secrets
        echo "Version in key vault is the same"
        needs_updating=false

        # retrieve package-id
        echo "retrieving package id"
        packageId=$(az keyvault secret show --vault-name $keyVaultName --name $secretName-packageId --query "value" -o tsv)
        echo "package id is $packageId"
    else
        echo "Version in key vault is $secret_val but current version is $chainCodeVersion.$chainCodeSequence"
        echo "Keyvault needs updating"
        needs_updating=true
    fi
fi

if [ "$needs_updating" = true ]; then
    echo "Making certificate using openssl"
    openssl req -nodes -x509 -newkey rsa:4096 -keyout crypto/key1.pem -out crypto/cert1.pem -subj "/C=${chaincodeCertificateCountry}/ST=${chaincodeCertificateState}/L=${chaincodeCertificateLocality}/O=${chaincodeCertificateOrganisation}/OU=Developer/CN=${COMP_NAME}.${NAMESPACE}/emailAddress=${SUPPORT_EMAIL}"
    Cert=$(awk 'NF {sub(/\r/, ""); printf "%s\n",$0;}' crypto/cert1.pem)

    echo "Preparing connection json template and saving to chaincode folder"
    connectionJson=$(cat $CHIANCODE_SHARED_ROOT/connection.json)
    connectionJson=$(jq '.address = $newVal' --arg newVal "${COMP_NAME}.${NAMESPACE}:${PORT}" <<<$connectionJson)
    connectionJson=$(jq '.root_cert = $newVal' --arg newVal "$Cert" <<<$connectionJson)
    echo $connectionJson > $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/connection.json

    while IFS= read -r line; do
        echo "$line"
    done < $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/connection.json

    echo "Preparing metadata json template and saving to chaincode folder"
    metadataJson=$(cat $CHIANCODE_SHARED_ROOT/metadata.json)
    metadataJson=$(jq '.label = $newVal' --arg newVal "${CHIANCODE_LABEL}" <<<$metadataJson)
    echo $metadataJson > $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/metadata.json

    while IFS= read -r line; do
        echo "$line"
    done < $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/metadata.json

    echo "Packaging chaincode"
    tar cfz code.tar.gz connection.json
    tar cfz ${COMP_NAME}.tgz metadata.json code.tar.gz

    cd $INSTALL_LOCATION

    echo "Installing chaincode"
    # usage: fabric lifecycle install <chaincode-label> <path> [flags]
    installInfo=$($FABRIC_EXECUTABLE_PATH lifecycle install $CHAINCODE_NAME $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/${COMP_NAME}.tgz)
    echo $installInfo
    arr=(${installInfo// / })

    packageId=${arr[6]}
    packageId=$(echo $packageId | tr -d \')

    echo "####################################"
    echo "PackageId for $CHAINCODE_NAME is as below. Please keep it stored for later."
    printf "\n"
    echo "PackageId = $packageId"
    printf $packageId > $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/packageId.txt
    echo "####################################"

    echo "Approving chaincode"
    # usage: fabric lifecycle approve <chaincode-name> <version> <package-id> <sequence>
    $FABRIC_EXECUTABLE_PATH lifecycle approve $CHAINCODE_NAME $CHAINCODE_VERSION $packageId  $CHAINCODE_SEQUENCE --policy "OR('$ORG_NAME.member')"
    retVal=$?
    [ $retVal -ne 0 ] && echo "Approving chaincode $CHAINCODE_NAME failed. Please check version and make sure sequence is incremented to match what's expected. See error message above for details. Failed version and sequence: $CHAINCODE_VERSION.$CHAINCODE_SEQUENCE" && exit 1

    echo "Commiting chaincode"
    # usage: fabric lifecycle commit <chaincode-name> <version> <sequence> [flags]
    $FABRIC_EXECUTABLE_PATH lifecycle commit $CHAINCODE_NAME $CHAINCODE_VERSION $CHAINCODE_SEQUENCE --policy "OR('$ORG_NAME.member')"
    retVal=$?
    [ $retVal -ne 0 ] && echo "Committing chaincode $CHAINCODE_NAME failed. Please check version and make sure sequence is incremented to match what's expected. See error message above for details. Failed version and sequence: $CHAINCODE_VERSION.$CHAINCODE_SEQUENCE" && exit 1

    echo "Creating kubernetes namespace"

    kubectl delete ns $NAMESPACE
    kubectl create ns $NAMESPACE

    echo "Creating kubernetes secrets"

    kubectl create secret generic $chaincodeCertificateName --from-file=$CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/crypto/cert1.pem -n $NAMESPACE
    kubectl create secret generic $chaincodeCertificateKeyName --from-file=$CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/crypto/key1.pem -n $NAMESPACE

    # update keyvault
    echo "Saving current chaincode version in key vault"
    az keyvault secret set --vault-name $keyVaultName --name $secretName -f $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/version.txt

    echo "Saving package id is key vault"    
    az keyvault secret set --vault-name $keyVaultName --name $secretName-packageId -f $CHAINCODE_DEPLOYMENT_ARTEFACT_LOCATION/packageId.txt
fi

##########
#### Patch k8s manifest, Build and Push Docker image ####
##########

echo "Updating template: $MANIFEST_FILE_PATH"

#updating component name for deployment
sed -i "s/CHAINCODE_DEPLOY_COMPONENT_NAME/${COMP_NAME}/g" $MANIFEST_FILE_PATH

#updating ACR name for deployment
sed -i "s/CHAINCODE_DEPLOY_ACR_NAME/${ACR_NAME}/g" $MANIFEST_FILE_PATH

#updating ACR REPO NAME
sed -i "s/CHAINCODE_DEPLOY_REPO/${ACR_REPO_NAME}/g" $MANIFEST_FILE_PATH

#updating TAG
sed -i "s/CHAINCODE_DEPLOY_TAG/${CHAINCODE_TAG}/g" $MANIFEST_FILE_PATH         

#updating PORT
sed -i "s/CHAINCODE_PORT/${PORT}/g" $MANIFEST_FILE_PATH

#updating ID
CHAINCODE_ID=$packageId
sed -i "s/CHAINCODE_DEPLOY_CHAINCODE_ID/${CHAINCODE_ID}/g" $MANIFEST_FILE_PATH

# print file to console
while IFS= read -r line; do
    echo "$line"
done < $MANIFEST_FILE_PATH

# todo: use a Azure Pipeline Docker@2 task rather than using docker login
echo "Logging into ACR"     
docker login -u $dockerUsername -p $dockerPwd $ACR_NAME

echo "Building Dockerfile"
cd $chainCodeFolder
docker build . -t $ACR_REPO_NAME:latest

echo "Pushing to ACR"
docker images

docker tag $ACR_REPO_NAME:latest $ACR_NAME/$ACR_REPO_NAME:$CHAINCODE_TAG
docker push $ACR_NAME/$ACR_REPO_NAME:$CHAINCODE_TAG

docker tag $ACR_REPO_NAME:latest $ACR_NAME/$ACR_REPO_NAME:latest          
docker push $ACR_NAME/$ACR_REPO_NAME:latest

# Apply manifest
echo "Applying kubernetes manifest"

kubectl config set-context --current --namespace=$NAMESPACE

if [ "$needs_updating" = true ]; then
    kubectl apply -f $MANIFEST_FILE_PATH # we can just call apply because namespace is deleted and recreated before
else
    kubectl replace --force -f $MANIFEST_FILE_PATH # since we don't delete the namesapace we need to update existing deployment
fi

echo "<END>=========$chainCodeUniqueName===========<END>"
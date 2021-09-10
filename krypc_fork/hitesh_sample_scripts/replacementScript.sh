
COMP_NAME=$1
ACR_NAME=$2
ACR_REPO_NAME=$3
PORT=$4
CHAINCODE_ID=$5
filePath=$6

if [ -z "${filePath}" ]; 
    filePath=$(realpath deploy.yaml)
fi

echo $filePath

#updating component name for deployment
sed -i "s/CHAINCODE_DEPLOY_COMPONENT_NAME/${COMP_NAME}/g" $filePath

#updating ACR name for deployment
sed -i "s/CHAINCODE_DEPLOY_ACR_NAME/${ACR_NAME}/g" $filePath

#updating ACR REPO NAME
sed -i "s/CHAINCODE_DEPLOY_REPO/${ACR_REPO_NAME}/g" $filePath

#updating PORT
sed -i "s/CHAINCODE_PORT/${PORT}/g" $filePath

#updating PORT
sed -i "s/CHAINCODE_DEPLOY_CHAINCODE_ID/${CHAINCODE_ID}/g" $filePath


cat -v $filePath
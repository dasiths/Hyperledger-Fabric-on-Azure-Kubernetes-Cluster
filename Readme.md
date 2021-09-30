# Hyper Ledger Fabric (HLF) 2.x on Azure Kubernetes Service (AKS)

Note: This pipeline is based on documentation in: https://github.com/krypc-code/Hyperledger-Fabric-on-Azure-Kubernetes-Cluster

This is an example how the same but done via an Azure DevOps Pipeline.

## Variables Required For Pipeline

```
# SPN and Subscription #
serviceConnection: comes-from-variable-group
hlfSubscription: comes-from-variable-group  

# Blob Storage for temporary storage of build artefacts #

tempArtefactBlobName: comes-from-variable-group # note: this need to be created prior
tempArtefactBlobStorageKey: comes-from-variable-group 
tempArtefactBlobContainerName: comes-from-variable-group # note: this need to be created prior

##### Blob Storage for saving generated orderer and peer profile #
profileBlobStorageResourceGroup: comes-from-variable-group # note: this need to be created prior
profileBlobName: comes-from-variable-group # note: this need to be created prior
profileBlobStorageFileShare: comes-from-variable-group

# ACR #
dockerId: comes-from-variable-group 
dockerUsername: comes-from-variable-group  
dockerPwd: comes-from-variable-group 
dockerImage: comes-from-variable-group
###### Key Vault ##########
keyVaultName: comes-from-parent-pipepine 

# HLF specific #
hlfRegion: comes-from-variable-group 
hlfUserName: comes-from-variable-group 
hlfCaPassword: comes-from-variable-group 
hlfAksClusterPeer: comes-from-variable-group 
hlfAksClusterOrderer: comes-from-variable-group 
hlfOrdererResourceGroup: comes-from-variable-group 
hlfPeerResourceGroup: comes-from-variable-group 
hlfOrdererOrganization: comes-from-variable-group  
hlfPeerOrganization: comes-from-variable-group 
hlfChannelName: comes-from-variable-group 
hlfNetworkName: comes-from-variable-group 
hlfContextName: comes-from-variable-group 
hlfTDeployToolingRootFolder: comes-from-parent-pipepine

# shared chaincode settings #
chaincodeRootFolder: comes-from-parent-pipepine
chaincodeSupportEmail: comes-from-parent-pipepine
chaincodeCertificateCountry: comes-from-parent-pipepine
chaincodeCertificateState: comes-from-parent-pipepine
chaincodeCertificateLocality: comes-from-parent-pipepine
chaincodeCertificateOrganisation: comes-from-parent-pipepine
chaincodeCertificateName: comes-from-parent-pipepine
chaincodeCertificateKeyName: comes-from-parent-pipepine 
adminProfileSecretName: comes-from-parent-pipepine
chaincodeSecretNamePrefix: comes-from-parent-pipepine 

# Individual chaincode settings #
testChainCodeFolder: comes-from-parent-pipepine
testChainCodeUniqueName: comes-from-parent-pipepine
testChainCodeUniqueLabel: comes-from-parent-pipepine
testChainCodeVersion: comes-from-variable-group 
testChainCodeSequence: comes-from-variable-group 
testChainCodeComponentName: comes-from-parent-pipepine
testChainCodeUniqueNamespace: comes-from-parent-pipepine
testChainCodePort: comes-from-parent-pipepine
```
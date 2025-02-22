# Hyperledger Fabric (HLF) 2.x on Azure Kubernetes Service (AKS)

Forked from:
> Hyperledger fabric developer network on few clicks. This offer is meant to provide Hyperledger Fabric as a Service using ARM Templates to spin off resources inside an AKS cluster. https://github.com/krypc-code/Hyperledger-Fabric-on-Azure-Kubernetes-Cluster

Further work:
> Further work on this has been done by Ahmed Salijee in https://github.com/ahmedsza/Hyperledger-Fabric-on-Azure-Kubernetes-Cluster


This is an example how the same can be done in an automated way via an Azure DevOps Pipeline. The idea is to have two pipelines. One for deploying the infrastructure (Orderer, Peer and Consortium/Channel operation) and one for deploying the chaincode. We have a reusable template `HLF_complete_template.yaml` and a script `deployChaincode.sh` to facilitate this.

We have an example using a single chaincode but you can easily extend this to support many chaincodes as all the required logic is reusable components.

## Variables Required For Pipeline

```
  # NOTE: All the variables used are listed below. Please keep this list up to date. They get injected from outside (i.e. variable group or pipeline using the template)

  ######## SPN and Subscription ##########
  # serviceConnection: comes-from-variable-group
  # hlfSubscription: comes-from-variable-group  

  ####### Blob Storage for temporary storage of build artefacts ########
  # This has to have public access
  # tempArtefactBlobName: comes-from-variable-group # note: this need to be created prior
  # tempArtefactBlobStorageKey: comes-from-variable-group 
  # tempArtefactBlobContainerName: comes-from-variable-group # note: this need to be created prior

  ## NOTE ## :
  # The above build artefacts are used for the azure functions provisioned. The Azure Functions have their source stored in the above blob container.
  # If you don't want the above blob container to have public access then refactor the azure function ARM template (mainTemplate.json funcNodeJsPackageUri variable) to use a url with a SAS token.
  
  ####### Blob Storage for saving generated orderer and peer profile ########
  # profileBlobStorageResourceGroup: comes-from-variable-group # note: this need to be created prior
  # profileBlobName: comes-from-variable-group # note: this need to be created prior
  # profileBlobStorageFileShare: comes-from-variable-group

  ######## ACR ############
  # dockerId: comes-from-variable-group 
  # dockerUsername: comes-from-variable-group  
  # dockerPwd: comes-from-variable-group 
  # dockerImage: comes-from-variable-group
  
  ######## Key Vault ##########
  # adminProfileKeyVaultName: comes-from-variable-group. This is where the connection profile will be saved so apps can use it.
  # chaincodePackageIdStorageKeyVaultName: comes-from-variable-group. This is where the deployed packaged id will be stored.  

  ######## HLF specific #########
  # hlfRegion: comes-from-variable-group 
  # hlfUserName: comes-from-variable-group 
  # hlfCaPassword: comes-from-variable-group 
  # hlfAksClusterPeer: comes-from-variable-group 
  # hlfAksClusterOrderer: comes-from-variable-group 
  # hlfOrdererResourceGroup: comes-from-variable-group 
  # hlfPeerResourceGroup: comes-from-variable-group 
  # hlfOrdererOrganization: comes-from-variable-group  
  # hlfPeerOrganization: comes-from-variable-group 
  # hlfChannelName: comes-from-variable-group 
  # hlfNetworkName: comes-from-variable-group 
  # hlfContextName: comes-from-variable-group 
  # hlfTDeployToolingRootFolder: comes-from-parent-pipepine

  ######## shared chaincode settings ########
  # chaincodeRootFolder: comes-from-parent-pipepine
  # chaincodeSupportEmail: comes-from-parent-pipepine
  # chaincodeCertificateCountry: comes-from-parent-pipepine
  # chaincodeCertificateState: comes-from-parent-pipepine
  # chaincodeCertificateLocality: comes-from-parent-pipepine
  # chaincodeCertificateOrganisation: comes-from-parent-pipepine
  # chaincodeCertificateName: comes-from-parent-pipepine
  # chaincodeCertificateKeyName: comes-from-parent-pipepine 
  # adminProfileSecretName: comes-from-parent-pipepine
  # chaincodeSecretNamePrefix: comes-from-parent-pipepine 

  ######## Individual chaincode settings ########
  ######## Test Chaincode ###########
  # testChainCodeFolder: comes-from-parent-pipepine
  # testChainCodeUniqueName: comes-from-parent-pipepine
  # testChainCodeUniqueLabel: comes-from-parent-pipepine
  # testChainCodeVersion: comes-from-variable-group 
  # testChainCodeSequence: comes-from-variable-group 
  # testChainCodeComponentName: comes-from-parent-pipepine
  # testChainCodeUniqueNamespace: comes-from-parent-pipepine
  # testChainCodePort: comes-from-parent-pipepine
```

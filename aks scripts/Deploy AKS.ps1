# This script deploys a new AKS cluster with OIDC issuer and Workload Identity enabled.
# It also creates an Application Gateway for containers managed by ALB controller.
# It also creates a sample application deployment and a gateway to test the traffic split scenario.

# This script requires the Azure CLI and kubectl to be installed.

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ClusterName,

    [Parameter()]
    [string]$Location = "EastUs",

    [Parameter()]
    [string]$VmSize = "Standard_DS2_v2",

    [Parameter()]
    [int]$NodeCount = 3
)

# Create a new resource group
az group create --name $ResourceGroupName --location $Location

# Deploy the .bicep file
#az deployment group create --resource-group $ResourceGroupName --template-file "deploy.bicep" --parameters clusterName=$ClusterName --parameters --locationocation=$Location

# Deploy new AKS cluster
az aks create `
    --node-count $NodeCount `
    --resource-group $ResourceGroupName `
    --name $ClusterName `
    --location  $Location `
    --node-vm-size $VmSize `
    --network-plugin azure `
    --enable-oidc-issuer `
    --enable-workload-identity `
    --generate-ssh-key

az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --overwrite-existing
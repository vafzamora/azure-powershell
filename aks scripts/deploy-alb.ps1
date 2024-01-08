# This script installs the ALB controller on an AKS cluster.
# It also creates an Application Gateway for containers managed by ALB controller.
# It also creates a sample application deployment and a gateway to test the traffic split scenario.

# This script requires the Azure CLI and kubectl to be installed.

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ClusterName
)

# Create a user managed identity for ALB controller and federate the identity as Workload Identity to use in the AKS cluster.
$IdentityResourceName='azure-alb-identity'

$mcResourceGroup=$(az aks show --resource-group $ResourceGroupName --name $ClusterName --query "nodeResourceGroup" -o tsv)
$mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -o tsv)

Write-Output "Creating identity $IdentityResourceName in resource group $ResourceGroupName"
az identity create --resource-group $ResourceGroupName --name $IdentityResourceName
$principalId="$(az identity show -g $ResourceGroupName -n $IdentityResourceName --query principalId -o tsv)"

Write-Output "Waiting 60 seconds to allow for replication of the identity..."
Start-Sleep 60

Write-Output "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --scope $mcResourceGroupId --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

Write-Output "Set up federation with AKS OIDC issuer"
$AksOidcIssuer="$(az aks show -n "$ClusterName" -g "$ResourceGroupName" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
az identity federated-credential create `
    --name "azure-alb-identity" `
    --identity-name "$IdentityResourceName" `
    --resource-group $ResourceGroupName `
    --issuer "$AksOidcIssuer" `
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# Install the ALB controller
C:\helm\helm.exe install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller `
    --version 0.6.3 `
    --set albController.podIdentity.clientID=$(az identity show -g $ResourceGroupName -n azure-alb-identity --query clientId -o tsv)

# Create Application Gateway for containers managed by ALB controller
$ClusterSubnetId=$(az vmss list --resource-group $mcResourceGroup --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)
$VNetName, $VNetResourceGroup, $VNetId = $(az network vnet show --ids $ClusterSubnetId --query '[name, resourceGroup, id]' -o tsv) -split "\t"

$SubentAddressPrefix='10.225.1.0/24'
$AlbSubnetName='alb-subnet' # subnet name can be any non-reserved subnet name (i.e. GatewaySubnet, AzureFirewallSubnet, AzureBastionSubnet would all be invalid)
az network vnet subnet create --resource-group $VNetResourceGroup --vnet-name $VNetName --name $AlbSubnetName --address-prefixes $SubentAddressPrefix --delegations 'Microsoft.ServiceNetworking/trafficControllers'
$AlbSubnetId=$(az network vnet subnet show `
                    --name $AlbSubnetName `
                    --resource-group $VNetResourceGroup `
                    --vnet-name $VNetName `
                    --query '[id]' `
                    --output tsv)

# Delegate AppGw for Containers Configuration Manager role to AKS Managed Cluster RG
az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type ServicePrincipal `
    --scope $mcResourceGroupId `
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Delegate Network Contributor permission for join to association subnet
az role assignment create `
    --assignee-object-id $principalId `
    --assignee-principal-type ServicePrincipal `
    --scope $AlbSubnetId `
    --role "4d97b98b-1d4f-4787-a291-c67834d212e7"

# Create Application Gateway for containers managed by ALB controller
@"
apiVersion: v1
kind: Namespace
metadata:
  name: alb-test-infra
"@ | kubectl apply -f -

@"
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-test
  namespace: alb-test-infra
spec:
  associations:
  - $AlbSubnetId
"@ | kubectl apply -f -

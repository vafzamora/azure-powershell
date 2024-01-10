# This script will add the keyvault-csi driver to the cluster

# receive ResourceGroup and ClusterName as parameters
param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string] $ClusterName, 

    [string] $KeyVaultName,
    [string] $KeyVaultResourceGroup
)

# if KeyVaultResourceGroup is not provided, use ResourceGroup
if ([string]::IsNullOrEmpty($KeyVaultResourceGroup)) {
    $KeyVaultResourceGroup = $ResourceGroup
}

# if KeyVaultName is not provided, use ClusterName concatenated with "-kv"
if ([string]::IsNullOrEmpty($KeyVaultName)) {
    $KeyVaultName = "$ClusterName-kv"
}

# enable keyvault-csi driver add-on
az aks enable-addons `
    --addons azure-keyvault-secrets-provider `
    --name $ClusterName `
    --resource-group $ResourceGroup

# use this command to check instalation
# kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver,secrets-store-provider-azure)'

# create a keyvault if it doesn't exist
az keyvault create `
    --name $KeyVaultName `
    --resource-group $KeyVaultResourceGroup `
    --enable-rbac-authorization  

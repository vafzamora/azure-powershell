param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string] $ClusterName, 

    [Parameter(Mandatory = $true)]
    [string] $KeyVaultName
)

# create role assignment for the cluster identity to access the keyvault
$identityClientId=$(az aks show -g $ResourceGroup -n $ClusterName --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
$tenantId=$(az account show --query tenantId -o tsv )
$keyVaultScope=$(az keyvault show --name $KeyVaultName --query id -o tsv)

$myClientId=$(az ad signed-in-user show --query id -o tsv)

az role assignment create `
    --role 'Key Vault Administrator' `
    --assignee $myClientId `
    --scope $keyVaultScope

az role assignment create `
    --role 'Key Vault Administrator' `
    --assignee $identityClientId `
    --scope $keyVaultScope

# create a secret in the keyvault called test-secret
az keyvault secret set `
    --vault-name $KeyVaultName `
    --name 'test-secret' `
    --value 'test-secret-value'

# create a SecretProviderClass object that exposes the secret as a volume
@"
# This is a SecretProviderClass example using user-assigned identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-user-msi
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"                # Set to true for using managed identity
    userAssignedIdentityID: $identityClientId   # Set the clientID of the user-assigned managed identity to use
    keyvaultName: $KeyVaultName                 # Set to the name of your key vault
    cloudName: ""                               # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: test-secret
          objectType: secret            # object types: secret, key, or cert
          objectVersion: ""             # [OPTIONAL] object versions, default to latest if empty
    tenantId: $tenantId                 # The tenant ID of the key vault
  secretObjects: 
  - secretName: csi-secret
    type: Opaque
    data: 
    - key: test-secret-secret
      objectName: test-secret
"@ | kubectl apply -f -


@"
# This is a sample pod definition for using SecretProviderClass and the user-assigned identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
spec:
  containers:
    - name: busybox
      image: registry.k8s.io/e2e-test-images/busybox:1.29-4
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
      env: 
      - name: SECRET_SECRET
        valueFrom:
          secretKeyRef: 
            name: csi-secret
            key: test-secret-secret
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-kvname-user-msi"
"@ | kubectl apply -f -
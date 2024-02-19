param(
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string] $ClusterName, 

    [Parameter(Mandatory = $true)]
    [string] $KeyVaultName
)

$certName='aks-ingress-cert'
$namespace='istio-ingress'

# Generate self-signed certificate using openssl on Linux or Windows Subsystem for Linux (WSL) 
#
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#     -out aks-ingress-tls.crt \
#     -keyout aks-ingress-tls.key \
#     -subj "/CN=demo.azure.com/O=aks-ingress-tls"

# openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key  -out $CERT_NAME.pfx
# skip Password prompt

# Import certificate into Key Vault using azure cli
az keyvault certificate import --vault-name $KeyVaultName --name $certName --file "../$certName.pfx"

$tenantId=$(az account show --query tenantId -o tsv )
$identityClientId=$(az aks show -g $ResourceGroup -n $ClusterName --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

kubectl create namespace $namespace

#Create SecretProviderClass
@"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-tls
spec:
  provider: azure
  secretObjects: 
    - secretName: ingress-tls-csi
      type: kubernetes.io/tls
      data: 
        - objectName: $certName
          key: tls.key
        - objectName: $certName
          key: tls.crt
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: $identityClientId
    keyvaultName: $KeyVaultName
    objects: |
      array:
        - |
          objectName: $certName
          objectType: secret
    tenantId: $tenantId
"@ | kubectl apply -n $namespace -f -


param location string = 'eastus'
param clusterName string = 'myAKSCluster'
param nodeCount int = 2
param nodeVMSize string = 'Standard_DS2_v2'


resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: '${clusterName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'aks-subnet'
  parent: vnet
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

resource albSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'alb-subnet'
  parent: vnet
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.27.7'
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'systemPool01'
        count: nodeCount
        vmSize: nodeVMSize
        osDiskSizeGB: 30
        osType: 'Linux'
        vnetSubnetID: aksSubnet.id
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'azure'
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    addonProfiles:{
    }
    oidcIssuerProfile: {
      enabled: true
    }
  }
}

output clusterFQDN string = aksCluster.properties.fqdn

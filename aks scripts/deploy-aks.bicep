param location string = 'eastus'
param clusterName string = 'myAKSCluster'
param nodeCount int = 2
param nodeVMSize string = 'Standard_DS2_v2'
param kubeVersion string
param sshPublicKey string
param adminUsername string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: kubeVersion
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'systempool'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        count: nodeCount
        vmSize: nodeVMSize
        osDiskSizeGB: 30
        osType: 'Linux'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
      networkPolicy: 'azure'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
      serviceCidr: '10.0.0.0/16'
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
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

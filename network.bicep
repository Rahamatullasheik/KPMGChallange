@description('Specify the environment type')
@allowed([
  'SBox'
  'prod'
])
param environmentType string

param location string
param nlocation string

param prefix string


resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vnet-${prefix}-hub-${environmentType}-${nlocation}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.168.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {       
          addressPrefix: '10.168.1.64/26'   
          networkSecurityGroup: {
            id: bastionNetworkSecurityGroup.id
          }
        }
      }
      {
        name: 'snet-${prefix}-dc-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.1.0/27'
          networkSecurityGroup:{
            id: DomainControllerNetworkSecurityGroup.id
          }
        }
      }

      {
        name: 'snet-${prefix}-mgmt-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.1.32/27'
          networkSecurityGroup: {
            id: WebNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: 'vnet-${prefix}-spoke-${environmentType}-${nlocation}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.168.10.0/24'
      ]
    }
    subnets: [
      {
        name: 'snet-${prefix}-webtier-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.10.32/27'
          networkSecurityGroup: {
            id: WebNetworkSecurityGroup.id
          }
        }
      }
      
      {
        name: 'snet-${prefix}-apptier-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.10.0/27'
          networkSecurityGroup: {
            id: appGatewayNetworkSecurityGroup.id
          }
        }
      }

      {
        name: 'snet-${prefix}-log-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.10.64/27'
          networkSecurityGroup: {
            id: LogNetworkSecurityGroup.id
          }
        }
      }

      {
        name: 'snet-${prefix}-prisql-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.10.96/27'
          networkSecurityGroup: {
            id: SqlPrimarySubnetNetworkSecurityGroup.id
          }
        }
      }
      {
        name: 'snet-${prefix}-secsql-${environmentType}-${nlocation}'
        properties: {
          addressPrefix: '10.168.10.128/27'
          networkSecurityGroup: {
            id: SqlSecondarySubnetNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
}



// hub and spoke peering
resource hubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  parent: hubVirtualNetwork
  name: 'peer-${prefix}-hub-${environmentType}-${nlocation}'
  properties: {
    remoteVirtualNetwork: {
      id: virtualNetwork.id
    }
  }
}


// NSGs for spoke network subnets
resource LogNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-log-${environmentType}-${nlocation}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTPS'
        properties: {
          access: 'Allow'
          description: 'Allow HTTPS'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 201
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
    }

    ]
  }
}

resource WebNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-app-${environmentType}-${nlocation}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTPS'
        properties: {
          access: 'Allow'
          description: 'Allow HTTPS'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 201
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
    }

    ]
  }
}
resource SqlSecondarySubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-prisql-${environmentType}-${nlocation}'
  location: location  
}

resource SqlPrimarySubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-secsql-${environmentType}-${nlocation}'
  location: location  
}

resource appGatewayNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-web-${environmentType}-${nlocation}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'ApplicationGateway'
        properties: {
          access: 'Allow'
          description: 'Allow Application Gateway'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          direction: 'Inbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      // {
      //   name: 'HTTP'
      //   properties: {
      //     access: 'Allow'
      //     description: 'Allow HTTP'
      //     destinationAddressPrefix: '*'
      //     destinationPortRange: '80'
      //     direction: 'Inbound'
      //     priority: 200
      //     protocol: 'Tcp'
      //     sourceAddressPrefix: '*'
      //     sourcePortRange: '*'
      //   }
      // }
      {
          name: 'HTTPS'
          properties: {
            access: 'Allow'
            description: 'Allow HTTPS'
            destinationAddressPrefix: '*'
            destinationPortRange: '443'
            direction: 'Inbound'
            priority: 201
            protocol: 'Tcp'
            sourceAddressPrefix: '*'
            sourcePortRange: '*'
          }
      }
    ]
  }
}


// NSGs for Hub network subnets
resource bastionNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-bas-${environmentType}-${nlocation}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebExperienceInBound'
        properties: {
          access: 'Allow'
          description: 'Allow our users in. Update this to be as restrictive as possible.'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowControlPlaneInBound'
        properties: {
          access: 'Allow'
          description: 'Service Requirement. Allow control plane access. Regional Tag not yet supported.'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowHealthProbesInBound'
        properties: {
          access: 'Allow'
          description: 'Service Requirement. Allow Health Probes.'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionHostToHostInBound'
        properties: {
          access: 'Allow'
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Inbound'
          priority: 130
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSshToVnetOutBound'
        properties: {
          access: 'Allow'
          description: 'Allow SSH out to the VNet'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '22'
          direction: 'Outbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowRdpToVnetOutBound'
        properties: {
          access: 'Allow'
          description: 'Allow RDP out to the VNet'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3389'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowControlPlaneOutBound'
        properties: {
          access: 'Allow'
          description: 'Required for control plane outbound. Regional prefix not yet supported'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          direction: 'Outbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionHostToHostOutBound'
        properties: {
          access: 'Allow'
          description: 'Service Requirement. Allow Required Host to Host Communication.'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Outbound'
          priority: 130
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionCertificateValidationOutBound'
        properties: {
          access: 'Allow'
          description: 'Service Requirement. Allow Required Session and Certificate Validation.'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 140
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          access: 'Deny'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Outbound'
          priority: 1000
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }

    ]
  }
}

resource DomainControllerNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-dc-${environmentType}-${nlocation}'
  location: location
}

resource ManagementVMNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: 'nsg-${prefix}-mgmt-${environmentType}-${nlocation}'
  location: location
}

output virtualNetworkName string = virtualNetwork.name
output hubVirtualNetworkName string = hubVirtualNetwork.name

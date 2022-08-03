@description('Specify the environment type')
@allowed([
  'SBox'
  'prod'
])
param environmentType string

param location string
param nlocation string

param prefix string

param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: 'AzureBastionSubnet'
  parent: virtualNetwork
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'pip-bas-${prefix}-as-${environmentType}-${nlocation}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-03-01' = {
  name: 'bas-${prefix}-as-${environmentType}-${nlocation}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
}

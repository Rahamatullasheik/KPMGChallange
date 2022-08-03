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

@allowed([
  'new'
  'existing'
])
param newOrExisting string

var applicationGatewayName = 'ag-${prefix}-${environmentType}-${nlocation}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource applicationGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: 'snet-${prefix}-apptier-${environmentType}-${nlocation}'
  parent: virtualNetwork
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: 'pip-ag-${prefix}-${environmentType}-${nlocation}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-03-01' = if (newOrExisting == 'new') {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfig'
        properties: {
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: applicationGatewaySubnet.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPortHttp'
        properties: {
          port: 80
        }
      }
    ]
    sslPolicy: {
      policyType: 'Predefined'
      policyName: 'AppGwSslPolicy20170401S'
    }
    backendAddressPools: [
      {
        name: 'defaultaddresspool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaulthttpsetting'
        properties: {
          port: 80
        }
      }
    ]
    httpListeners: [
      {
        name: 'defaulthttplistener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontendIpConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'frontendPortHttp')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultroutingrule'
        properties:{
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'defaulthttplistener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'defaultaddresspool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'defaulthttpsetting')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'      
    }
  }
}

output applicationGatewayName string = applicationGateway.name

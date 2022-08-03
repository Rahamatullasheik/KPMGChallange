@description('Specify the environment type')
@allowed([
  'SBox'
  'prod'
])
param environmentType string

param location string

param nlocation string

param prefix string = 'as'


@allowed([
  'new'
  'existing'
])
@description('Is this a new deployment? Application Gateway will only be created in a new deployment as it is managed by AGIC.')
param newOrExisting string = 'new'

// param aksSkuTier string = 'Free'

module networkModule 'network.bicep' = {
  name: 'networkDeploy'
  params: {
    environmentType: environmentType
    location: location
    nlocation: nlocation
    prefix: prefix
  }
}

module applicationGatewayModule 'applicationGateway.bicep' = {
  name: 'applicationGatewayDeploy'
  params: {
    environmentType: environmentType
    location: location
    nlocation: nlocation
    prefix: prefix
    virtualNetworkName: networkModule.outputs.virtualNetworkName
    newOrExisting: newOrExisting
  }
}

// module bastionModule 'bastion.bicep' = {
//   name: 'bastionDeploy'
//   params: {
//     environmentType: environmentType
//     location: location
//     prefix: prefix
//     virtualNetworkName: networkModule.outputs.hubVirtualNetworkName
//   }
// }

// resource popKeyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
//   name: 'kv-pop-s-${environmentType}-${location}'
//   scope: resourceGroup('rg-pop-keyvault-${environmentType}')
// }

module jumpvmmodule 'jump-vm.bicep' = {
  name: 'JumpvmDeploy'
  params: {
    environmentType: environmentType
    location: location
    nlocation: nlocation
    prefix: prefix
    vmPassword: 'p5AigQ3RxGeFToS6RnxR'//popKeyVault.getSecret('jumpVMPassword')
    virtualNetworkName: networkModule.outputs.hubVirtualNetworkName
  }
 }
 



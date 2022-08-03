@description('Specify the environment type')
@allowed([
  'SBox'
  'prod'
])
param environmentType string

param location string

param nlocation string

param vmSize string = 'Standard_DS2_v2'

param prefix string

param vmAdmin string = 'vmadmin'

@secure()
param vmPassword string

param virtualNetworkName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: virtualNetworkName
}

resource ManagementVMSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: 'snet-${prefix}-mgmt-${environmentType}-${nlocation}'
  parent: virtualNetwork
}

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nic-${prefix}-${environmentType}-${nlocation}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${ManagementVMSubnet.id}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}


resource avevm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'vm-${prefix}-${environmentType}-${nlocation}'
  location: location
  // zones: [
  //   '1'
  // ]
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: 'osdisk-${prefix}-${environmentType}-${nlocation}'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: prefix
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  } 


}

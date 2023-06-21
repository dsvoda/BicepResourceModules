targetScope = 'subscription'

@description('Suffix for all resources')
param suffix string = 'gobi'

@description('Location for all resources')
param location string = 'eastus'

param deploymentDate string = utcNow('yyyy-MM-dd')

@description('AVD Admin Group ID')
param avdAdminGroupResourceId string

@description('AVD User Group ID')
param avdUserGroupResourceId string

@description('Local Gateway IP Address - Customer On-Prem IP Address')
param localGatewayIpAddress string

@description('Resource group tags')
var resourceGroupTags = {
  CreatedBy: 'Gobi'
  DeploymentDate: deploymentDate
}

@description('AVD Resource tags')
var avdResourceTags = {
  CreatedBy: 'Gobi'
  DeploymentDate: deploymentDate
  Environment: 'prod'
  Workload: 'avd'
}

@description('Resource Group Names')
var resourceGroupNames = [
  'rg-ad'
  'rg-avd'
  'rg-network'
  'rg-backup'
  'rg-monitor'
  'rg-imagebuilder'
]

@description('Network Security Groups to be created')
var networkSecurityGroups = [
  'nsg-prod'
  'nsg-avd'
  'nsg-ad'
]

@description('VM Local Admin Username')
param vmLocalAdminUsername string

@description('VM Local Admin Password')
@secure()
param vmLocalAdminPassword string

resource rgLoop 'Microsoft.Resources/resourceGroups@2021-04-01' = [for name in resourceGroupNames: {
  name: name
  location: location
}]

module lawAvd './modules/OperationalInsights/workspaces/main.bicep' = {
  name: 'lawAvd'
  scope: resourceGroup('rg-monitor')
  dependsOn: [
    rgLoop
  ]
  params: {
    location: location
    name: 'law-avd-${suffix}'
    tags: avdResourceTags
    serviceTier: 'PerGB2018'
    dailyQuotaGb: 1
    dataRetention: 30
    dataSources: []
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    lock: 'CanNotDelete'
  }
}

module nsgs './modules/Network/networkSecurityGroups/main.bicep' = [for nsg in networkSecurityGroups: {
  name: nsg
  scope: resourceGroup('rg-network')
  dependsOn: [ rgLoop ]
  params: {
    name: nsg
    location: location
    tags: resourceGroupTags
    lock: 'CanNotDelete'
  }
}]

module network './modules/Network/virtualNetworks/main.bicep' = {
  name: 'network'
  scope: resourceGroup('rg-network')
  dependsOn: [
    nsgs
  ]
  params: {
    location: location
    name: 'vnet-${suffix}'
    tags: resourceGroupTags
    lock: 'CanNotDelete'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    subnets: [
      {
        name: 'prod-subnet'
        addressPrefix: '10.0.1.0/24'
        networkSecurityGroup: {
          id: nsgs[0].outputs.resourceId
        }
      }
      {
        name: 'avd-subnet'
        addressPrefix: '10.0.2.0/24'
        networkSecurityGroup: {
          id: nsgs[1].outputs.resourceId
        }
      }
      {
        name: 'ad-subnet'
        addressPrefix: '10.0.3.0/24'
        networkSecurityGroup: {
          id: nsgs[2].outputs.resourceId
        }
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.4.0/24'
      }
    ]
    dnsServers: [
      '10.0.3.4'
      '8.8.8.8'
    ]
  }
}

module vpnPublicIp './modules/Network/publicIPAddresses/main.bicep' = {
  name: 'vpnPublicIp'
  scope: resourceGroup('rg-network')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'pip-vpn-${suffix}'
    tags: resourceGroupTags
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    skuName: 'Standard'
    skuTier: 'Regional'
    lock: 'CanNotDelete'
  }
}

module vpnGateway './modules/Network/virtualNetworkGateways/main.bicep' = {
  name: 'vpnGateway'
  scope: resourceGroup('rg-network')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'vpnGateway-${suffix}'
    tags: resourceGroupTags
    vpnType: 'RouteBased'
    gatewayType: 'Vpn'
    skuName: 'Basic'
    vNetResourceId: network.outputs.resourceId
    lock: 'CanNotDelete'
    vpnGatewayGeneration: 'Generation1'
    vpnClientAddressPoolPrefix: ''
    activeActive: false
    enableBgp: false
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    diagnosticMetricsToEnable: [
      'AllMetrics'
    ]
  }
}

module vpnLocalGateway './modules/Network/localNetworkGateways/main.bicep' = {
  name: 'vpnLocalGateway'
  scope: resourceGroup('rg-network')
  dependsOn: [
    vpnGateway
  ]
  params: {
    location: location
    name: 'vpnLocalGateway-${suffix}'
    tags: resourceGroupTags
    localGatewayPublicIpAddress: localGatewayIpAddress
    localAddressPrefixes: [
      '192.168.0.0/24'
    ]
    lock: 'CanNotDelete'
  }
}

module vpnConnection './modules/Network/connections/main.bicep' = {
  name: 'vpnConnection'
  scope: resourceGroup('rg-network')
  dependsOn: [
    vpnGateway
    vpnLocalGateway
  ]
  params: {
    location: location
    name: 'vpnConnection-${suffix}'
    tags: resourceGroupTags
    connectionType: 'IPsec'
    enableBgp: false
    lock: 'CanNotDelete'
    virtualNetworkGateway1: vpnGateway
    localNetworkGateway2: vpnLocalGateway
    vpnSharedKey: 'Gobi@123'
    customIPSecPolicy: {
      saLifeTimeSeconds: 27000
      saDataSizeKilobytes: 102400000
      ipsecEncryption: 'AES256'
      ipsecIntegrity: 'SHA256'
      ikeEncryption: 'AES256'
      ikeIntegrity: 'SHA256'
      dhGroup: 'DHGroup2'
      pfsGroup: 'PFS2'
    }
  }
}

module rsvault './modules/RecoveryServices/vaults/main.bicep' = {
  name: 'rsvault'
  scope: resourceGroup('rg-backup')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'rsv-${suffix}'
    tags: resourceGroupTags
    publicNetworkAccess: 'Disabled'
    lock: 'CanNotDelete'
    backupConfig: {
      enableBackup: true
      enableAutoSnapshot: true
      enableAutoSnapshotFrequencyInHours: 12
      enableAutoSnapshotRetention: true
      enableAutoSnapshotRetentionInDays: 7
      enableInstantRestore: true
      enableRpo: true
      enableRpoInSeconds: 3600
      enableRpoAlert: true
    }
  }
}

module dailyVmBackup './modules/RecoveryServices/vaults/backupPolicies/main.bicep' = {
  name: 'dailyVmBackup'
  scope: resourceGroup('rg-backup')
  dependsOn: [
    rsvault
  ]
  params: {
    name: 'dailyVmPolicy'
    recoveryVaultName: rsvault.outputs.name
    properties: {
      backupManagementType: 'AzureIaasVM'
      protectedItemsCount: 0
      retentionPolicy: {
        dailySchedule: {
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 7
            durationType: 'Weeks'
          }
          timeZone: 'EST'
        }
        weeklySchedule: {
          daysOfTheWeek: [
            'Sunday'
          ]
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 4
            durationType: 'Weeks'
          }
          timeZone: 'EST'
        }
        monthlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleDaily: {
            daysOfTheMonth: [
              1
            ]
          }
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 12
            durationType: 'Months'
          }
          timeZone: 'EST'
        }
        yearlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleDaily: {
            daysOfTheMonth: [
              1
            ]
          }
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 2
            durationType: 'Years'
          }
          timeZone: 'EST'
        }
      }
      timeZone: 'EST'
    }
  }
}

module dailyFilePolicy './modules/RecoveryServices/vaults/backupPolicies/main.bicep' = {
  name: 'dailyFilePolicy'
  scope: resourceGroup('rg-backup')
  dependsOn: [
    rsvault
  ]
  params: {
    name: 'dailyFilePolicy'
    recoveryVaultName: rsvault.outputs.name
    properties: {
      backupManagementType: 'AzureStorage'
      protectedItemsCount: 0
      retentionPolicy: {
        dailySchedule: {
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 7
            durationType: 'Weeks'
          }
          timeZone: 'EST'
        }
        weeklySchedule: {
          daysOfTheWeek: [
            'Sunday'
          ]
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 4
            durationType: 'Weeks'
          }
          timeZone: 'EST'
        }
        monthlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleDaily: {
            daysOfTheMonth: [
              1
            ]
          }
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 12
            durationType: 'Months'
          }
          timeZone: 'EST'
        }
        yearlySchedule: {
          retentionScheduleFormatType: 'Weekly'
          retentionScheduleDaily: {
            daysOfTheMonth: [
              1
            ]
          }
          retentionScheduleWeekly: {
            daysOfTheWeek: [
              'Sunday'
            ]
            weeksOfTheMonth: [
              'First'
            ]
          }
          retentionTimes: [
            '2021-01-01T00:00:00Z'
          ]
          retentionDuration: {
            count: 2
            durationType: 'Years'
          }
          timeZone: 'EST'
        }
      }
      timeZone: 'EST'
    }
  }
}

module aadds './modules/AAD/DomainServices/main.bicep' = {
  name: 'aadds'
  scope: resourceGroup('rg-aad')
  dependsOn: [
    rsvault
  ]
  params: {
    location: location
    name: 'aadds-${suffix}'
    domainName: 'avd.gobi.com'
    tags: resourceGroupTags
    notifyGlobalAdmins: 'Enabled'
    ntlmV1: 'Disabled'
    tlsV1: 'Disabled'
    ldaps: 'Disabled'
    sku: 'Standard'
    lock: 'CanNotDelete'
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    diagnosticLogCategoriesToEnable: [
      'allLogs'
    ]
  }
}

module hostpool './modules/DesktopVirtualization/hostPools/main.bicep' = {
  name: 'hostpool-${suffix}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    aadds
  ]
  params: {
    name: 'hp-${suffix}'
    location: location
    tags: avdResourceTags
    friendlyName: 'hp-${suffix}'
    description: 'Host Pool for ${suffix}'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    type: 'Pooled'
    personalDesktopAssignmentType: 'Automatic'
    maxSessionLimit: 10
    validationEnvironment: false
    startVMOnConnect: true
    customRdpProperty: ''
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    diagnosticLogCategoriesToEnable: [
      'allLogs'
    ]
  }
}

module applicationGroup './modules/DesktopVirtualization/applicationGroups/main.bicep' = {
  name: 'applicationGroup-${suffix}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    workspace
  ]
  params: {
    name: 'ag-${suffix}'
    location: location
    tags: avdResourceTags
    friendlyName: 'ag-${suffix}'
    description: 'Application Group for ${suffix}'
    applicationGroupType: 'Desktop'
    hostpoolName: hostpool.outputs.name
  }
}

module workspace './modules/DesktopVirtualization/workspaces/main.bicep' = {
  name: 'workspace-${suffix}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    hostpool
  ]
  params: {
    name: 'ws-${suffix}'
    location: location
    tags: avdResourceTags
    friendlyName: 'ws-${suffix}'
    description: 'Workspace for ${suffix}'
    appGroupResourceIds: [
      avdAdminGroupResourceId
      avdUserGroupResourceId
    ]
  }
}

module stgAvdProfiles './modules/Storage/storageAccounts/main.bicep' = {
  name: 'stgAvdProfiles'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'stgavdprofiles${suffix}'
    tags: avdResourceTags
    kind: 'FileStorage'
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false
    allowCrossTenantReplication: false
    largeFileSharesState: 'Disabled'
    fileServices: {
      isSmbEnabled: true
      protocolSettings: {
        smb: {
          version: 'SMB3'
        }
      }
    }
    publicNetworkAccess: 'Disabled'
    skuName: 'Standard_LRS'
    lock: 'CanNotDelete'
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    diagnosticMetricsToEnable: [
      'Transaction'
    ]
  }
}

module stgAvdProfilesShare './modules/Storage/storageAccounts/fileServices/main.bicep' = {
  name: 'stgAvdProfilesShare'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    stgAvdProfiles
  ]
  params: {
    name: 'profiles'
    storageAccountName: stgAvdProfiles.outputs.name
    shares: [
      {
        name: 'profiles'
        quota: 1024
        backupEnabled: true
        accessTier: 'Hot'
        backupPolicyId: dailyFilePolicy.outputs.resourceId
      }
    ]
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    diagnosticLogCategoriesToEnable: [
      'allLogs'
    ]
    diagnosticMetricsToEnable: [
      'Transaction'
    ]
  }
}

module stgAvdProfilesShareFolder './modules/Storage/storageAccounts/fileServices/shares/main.bicep' = {
  name: 'stgAvdProfilesShareFolder'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    stgAvdProfilesShare
  ]
  params: {
    name: 'profiles'
    storageAccountName: stgAvdProfilesShare.outputs.name
    roleAssignments: []
  }
}

module azDcNic './modules/Network/networkInterfaces/main.bicep' = {
  name: 'azDcNic'
  scope: resourceGroup('rg-ad')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'nic-azdc-${suffix}'
    tags: avdResourceTags
    enableAcceleratedNetworking: true
    networkSecurityGroupResourceId: nsgs[2].outputs.resourceId
    ipConfigurations: [
      {
        name: 'ipconfig-azdc-${suffix}'
        subnet: {
          id: network.outputs.subnetResourceIds[2]
        }
        privateIPAllocationMethod: 'Static'
        privateIPAddress: '10.0.3.4'
        privateIPAddressVersion: 'IPv4'
      }
    ]
  }
}

module azDc './modules/Compute/virtualMachines/main.bicep' = {
  name: 'az-dc-01'
  scope: resourceGroup('rg-ad')
  dependsOn: [
    azDcNic
  ]
  params: {
    adminUsername: vmLocalAdminUsername
    adminPassword: vmLocalAdminPassword
    location: location
    name: 'az-dc-01'
    tags: resourceGroupTags
    vmSize: 'Standard_D2s_v3'
    osDisk: {
      name: 'az-dc-01-osdisk'
      caching: 'ReadWrite'
      createOption: 'FromImage'
      diskSizeGB: 128
    }
    imageReference: {
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter'
      version: 'latest'
    }
    nicConfigurations: [
      {
        name: 'nic-azdc-${suffix}'
        properties: {
          primary: true
          ipConfigurations: [
            {
              name: 'ipconfig-azdc-${suffix}'
              properties: {
                primary: true
              }
            }
          ]
        }
      }
    ]
    osType: 'Windows'
    licenseType: 'Windows_Server'
    lock: 'CanNotDelete'
    diagnosticWorkspaceId: lawAvd.outputs.resourceId
    diagnosticLogsRetentionInDays: 30
    backupVaultName: lawAvd.outputs.name
    backupPolicyName: 'dailyVmPolicy'
    backupVaultResourceGroup: 'rg-backup'
  }
}

module keyVault './modules/KeyVault/vaults/main.bicep' = {
  name: 'keyVault'
  scope: resourceGroup('rg-imagebuilder')
  dependsOn: [
    network
  ]
  params: {
    name: 'kv-${suffix}'
    location: location
    tags: resourceGroupTags
    lock: 'CanNotDelete'
    enableVaultForDeployment: true
    enableSoftDelete: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableVaultForTemplateDeployment: true
    vaultSku: 'standard'
  }
}

module imageGallery './modules/Compute/galleries/main.bicep' = {
  name: 'imageGallery'
  scope: resourceGroup('rg-imagebuilder')
  dependsOn: [
    rgLoop
  ]
  params: {
    name: 'ig-${suffix}'
    location: location
    tags: resourceGroupTags
    lock: 'CanNotDelete'
    description: 'Image Gallery for ${suffix}'
  }
}

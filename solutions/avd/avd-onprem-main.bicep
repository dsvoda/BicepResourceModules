targetScope = 'subscription'

@description('Suffix for all resources')
param suffix string = 'gobi'

@description('Location for all resources')
param location string = 'eastus'

@description('Environment for all resources')
param environment string = 'prod'

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
  Environment: environment
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

@description('vNet Address Prefix')
param vNetAddressPrefix string = '10.0.0.0/16'

@description('Subnets')
var subnets = [
  {
    name: 'snet-prod'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'snet-avd'
    addressPrefix: '10.0.2.0/24'
  }
  {
    name: 'snet-ad'
    addressPrefix: '10.0.3.0/24'
  }
  {
    name: 'snet-gateway'
    addressPrefix: '10.0.4.0/24'
  }
]

@description('vNet DNS Servers')
var vNetDnsServers = [
  '8.8.8.8'
  '8.8.4.4'
]

@description('VM Local Admin Username')
param vmLocalAdminUsername string

@description('VM Local Admin Password')
@secure()
param vmLocalAdminPassword string

@description('DC VM Size')
param dcVmSize string = 'Standard_D4s_v3'

@description('DC VM Image Publisher')
param dcVmGalleryImagePublisher string = 'microsoftwindowsserver'

@description('DC VM Image Offer')
param dcVmGalleryImageOffer string = 'windowsserver'

@description('DC VM Image SKU')
param dcVmGalleryImageSKU string = '2022-datacenter-azure-edition'

@description('GIVM Size')
param givmSize string = 'Standard_D4s_v3'

@description('GIVM Image Publisher')
param givmGalleryImagePublisher string = 'microsoftwindowsdesktop'

@description('GIVM Image Offer')
param givmGalleryImageOffer string = 'office-365'

@description('GIVM Image SKU')
param givmGalleryImageSKU string = 'win10-22h2-avd-m365-g2'

@description('VM Time Zone')
param vmTimeZone string = 'Eastern Standard Time'

@description('Do not modify, used to set unique value for resource deployment.')
param time string = utcNow()

resource rgLoop 'Microsoft.Resources/resourceGroups@2021-04-01' = [for name in resourceGroupNames: {
  name: name
  location: location
}]

module lawAvd '../../modules/Operational-Insights/workspaces/main.bicep' = {
  name: 'lawAvd-${time}'
  scope: resourceGroup('rg-monitor')
  dependsOn: [
    rgLoop
  ]
  params: {
    location: location
    name: 'law-avd-${location}-${suffix}'
    tags: avdResourceTags
    skuName: 'PerGB2018'
    dailyQuotaGb: 1
    dataRetention: 30
    dataSources: []
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    lock: 'CanNotDelete'
  }
}

module nsgs '../../modules/Network/network-Security-Groups/main.bicep' = [for nsg in networkSecurityGroups: {
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

module network '../../modules/Network/virtual-Networks/main.bicep' = {
  name: 'network-${time}'
  scope: resourceGroup('rg-network')
  dependsOn: [
    nsgs
  ]
  params: {
    location: location
    name: 'vnet-${location}-${environment}-${suffix}'
    tags: resourceGroupTags
    lock: 'CanNotDelete'
    addressPrefixes: [
      vNetAddressPrefix
    ]
    subnets: [
      {
        name: subnets[0].name
        addressPrefix: subnets[0].addressPrefix
        networkSecurityGroup: {
          id: nsgs[0].outputs.resourceId
        }
      }
      {
        name: subnets[1].name
        addressPrefix: subnets[1].addressPrefix
        networkSecurityGroup: {
          id: nsgs[1].outputs.resourceId
        }
      }
      {
        name: subnets[2].name
        addressPrefix: subnets[2].addressPrefix
        networkSecurityGroup: {
          id: nsgs[2].outputs.resourceId
        }
      }
      {
        name: subnets[3].name
        addressPrefix: subnets[3].addressPrefix
      }
    ]
    dnsServers: [
      vNetDnsServers[0]
      vNetDnsServers[1]
    ]
  }
}

module vpnPublicIp '../../modules/Network/public-IP-Addresses/main.bicep' = {
  name: 'vpnPublicIp-${time}'
  scope: resourceGroup('rg-network')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'pip-vpn-${location}-${suffix}'
    tags: resourceGroupTags
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
    skuName: 'Standard'
    skuTier: 'Regional'
    lock: 'CanNotDelete'
  }
}

module vpnGateway '../../modules/Network/virtual-Network-Gateways/main.bicep' = {
  name: 'vpnGateway-${time}'
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

module vpnLocalGateway '../../modules/Network/local-Network-Gateways/main.bicep' = {
  name: 'vpnLocalGateway-${time}'
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

module vpnConnection '../../modules/Network/connections/main.bicep' = {
  name: 'vpnConnection-${time}'
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

module rsvault '../../modules/Recovery-Services/vaults/main.bicep' = {
  name: 'rsvault-${time}'
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

module dailyVmBackup '../../modules/Recovery-Services/vaults/backup-Policies/main.bicep' = {
  name: 'dailyVmBackup-${time}'
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

module dailyFilePolicy '../../modules/Recovery-Services/vaults/backup-Policies/main.bicep' = {
  name: 'dailyFilePolicy-${time}'
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

module hostpool '../../modules/Desktop-Virtualization/host-Pools/main.bicep' = {
  name: 'hostpool-${time}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    network
  ]
  params: {
    name: 'hp-${location}-${environment}-${suffix}'
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

module applicationGroup '../../modules/Desktop-Virtualization/application-Groups/main.bicep' = {
  name: 'applicationGroup-${time}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    workspace
  ]
  params: {
    name: 'ag-${location}-${environment}-${suffix}'
    location: location
    tags: avdResourceTags
    friendlyName: 'ag-${suffix}'
    description: 'Application Group for ${suffix}'
    applicationGroupType: 'Desktop'
    hostpoolName: hostpool.outputs.name
  }
}

module workspace '../../modules/Desktop-Virtualization/workspaces/main.bicep' = {
  name: 'workspace-${time}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    hostpool
  ]
  params: {
    name: 'ws-${location}-${environment}-${suffix}'
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

module stgAvdProfiles '../../modules/Storage/storage-Accounts/main.bicep' = {
  name: 'stgAvdProfiles-${time}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    network
  ]
  params: {
    location: location
    name: 'stgfslprofiles${suffix}'
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

module stgAvdProfilesShare '../../modules/Storage/storage-Accounts/file-Services/main.bicep' = {
  name: 'stgAvdProfilesShare-${time}'
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

module stgAvdProfilesShareFolder '../../modules/Storage/storage-Accounts/file-Services/shares/main.bicep' = {
  name: 'stgAvdProfilesShareFolder-${time}'
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

module azDcNic '../../modules/Network/network-Interfaces/main.bicep' = {
  name: 'azDcNic-${time}'
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

module azDc '../../modules/Compute/virtual-Machines/main.bicep' = {
  name: 'az-dc-01-${time}'
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
    vmSize: dcVmSize
    osDisk: {
      name: 'az-dc-01-osdisk'
      caching: 'ReadWrite'
      createOption: 'FromImage'
      diskSizeGB: 128
    }
    imageReference: {
      publisher: dcVmGalleryImagePublisher
      offer: dcVmGalleryImageOffer
      sku: dcVmGalleryImageSKU
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
    timeZone: vmTimeZone
    bootDiagnostics: true
    monitoringWorkspaceId: lawAvd.outputs.resourceId
    enableAutomaticUpdates: false
  }
}

module imageGallery '../../modules/Compute/galleries/main.bicep' = {
  name: 'imageGallery-${time}'
  scope: resourceGroup('rg-imagebuilder')
  dependsOn: [
    rgLoop
  ]
  params: {
    name: 'ig_${suffix}'
    location: location
    tags: resourceGroupTags
    lock: 'CanNotDelete'
    description: 'Image Gallery for ${suffix}'
  }
}

module imageGalleryImage '../../modules/compute/galleries/images/main.bicep' = {
  name: 'imageGalleryImage-${time}'
  scope: resourceGroup('rg-imagebuilder')
  dependsOn: [
    imageGallery
  ]
  params: {
    name: 'img-${suffix}'
    location: location
    tags: avdResourceTags
    galleryName: imageGallery.outputs.name
    description: 'Image for ${suffix}'
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    isAcceleratedNetworkSupported: 'true'
    planPublisherName: givmGalleryImagePublisher
    offer: givmGalleryImageOffer
    sku: givmGalleryImageSKU
  } 
}

module givm '../../modules/compute/virtual-machines/main.bicep' = {
  name: 'givm-${time}'
  scope: resourceGroup('rg-avd')
  dependsOn: [
    network
    imageGalleryImage
    stgAvdProfilesShareFolder
  ]
  params: {
    name: 'givm-${location}-${environment}-${suffix}'
    location: location
    tags: avdResourceTags
    vmSize: givmSize
    imageReference: {
      imageid: imageGalleryImage.outputs.resourceId
    }
    osType: 'Windows'
    osDisk: {
      name: 'osdisk-givm-${location}-${environment}-${suffix}'
      caching: 'ReadWrite'
      createOption: 'FromImage'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    nicConfigurations: [
      {
        name: 'nic-givm-${location}-${environment}-${suffix}'
        properties: {
          ipConfigurations: [
            {
              name: 'ipconfig-givm-${location}-${environment}-${suffix}'
              properties: {
                subnet: {
                  id: network.outputs.subnetResourceIds[1]
                }
                privateIPAllocationMethod: 'Dynamic'
              }
            }
          ]
        }
      }
    ]
    adminUsername: vmLocalAdminPassword
    adminPassword: vmLocalAdminPassword
    enableAutomaticUpdates: false
    licenseType: 'Windows_Client'
    timeZone: vmTimeZone
  }
}

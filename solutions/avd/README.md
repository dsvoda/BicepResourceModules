# avd-main

This Bicep file deploys Azure Virtual Desktop (AVD) resources for a main deployment.

Bicep file for Azure Virtual Desktop (AVD) main deployment

## Parameters

Parameter name | Required | Description
-------------- | -------- | -----------
suffix         | No       | Suffix for all resources
location       | No       | Location for all resources
deploymentDate | No       |
avdAdminGroupResourceId | Yes      | AVD Admin Group ID
avdUserGroupResourceId | Yes      | AVD User Group ID
localGatewayIpAddress | Yes      | Local Gateway IP Address - Customer On-Prem IP Address
vmLocalAdminUsername | Yes      | VM Local Admin Username
vmLocalAdminPassword | Yes      | VM Local Admin Password

### suffix

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Suffix for all resources

- Default value: `gobi`

### location

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

Location for all resources

- Default value: `eastus`

### deploymentDate

![Parameter Setting](https://img.shields.io/badge/parameter-optional-green?style=flat-square)

- Default value: `[utcNow('yyyy-MM-dd')]`

### avdAdminGroupResourceId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

AVD Admin Group ID

### avdUserGroupResourceId

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

AVD User Group ID

### localGatewayIpAddress

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

Local Gateway IP Address - Customer On-Prem IP Address

### vmLocalAdminUsername

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

VM Local Admin Username

### vmLocalAdminPassword

![Parameter Setting](https://img.shields.io/badge/parameter-required-orange?style=flat-square)

VM Local Admin Password

## Snippets

### Parameter file

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "template": "avd-main.json"
    },
    "parameters": {
        "suffix": {
            "value": "gobi"
        },
        "location": {
            "value": "eastus"
        },
        "deploymentDate": {
            "value": "[utcNow('yyyy-MM-dd')]"
        },
        "avdAdminGroupResourceId": {
            "value": ""
        },
        "avdUserGroupResourceId": {
            "value": ""
        },
        "localGatewayIpAddress": {
            "value": ""
        },
        "vmLocalAdminUsername": {
            "value": ""
        },
        "vmLocalAdminPassword": {
            "reference": {
                "keyVault": {
                    "id": ""
                },
                "secretName": ""
            }
        }
    }
}
```

# Virtual Network Subnets `[Microsoft.Network/virtualNetworks/subnets]`

This module deploys a Virtual Network Subnet.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)
- [Notes](#Notes)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Authorization/roleAssignments` | [2022-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Authorization/2022-04-01/roleAssignments) |
| `Microsoft.Network/virtualNetworks/subnets` | [2023-04-01](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Network/2023-04-01/virtualNetworks/subnets) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`addressPrefix`](#parameter-addressprefix) | string | The address prefix for the subnet. |

**Conditional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`virtualNetworkName`](#parameter-virtualnetworkname) | string | The name of the parent virtual network. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`addressPrefixes`](#parameter-addressprefixes) | array | List of address prefixes for the subnet. |
| [`applicationGatewayIPConfigurations`](#parameter-applicationgatewayipconfigurations) | array | Application gateway IP configurations of virtual network resource. |
| [`delegations`](#parameter-delegations) | array | The delegations to enable on the subnet. |
| [`enableDefaultTelemetry`](#parameter-enabledefaulttelemetry) | bool | Enable telemetry via a Globally Unique Identifier (GUID). |
| [`ipAllocations`](#parameter-ipallocations) | array | Array of IpAllocation which reference this subnet. |
| [`name`](#parameter-name) | string | The Name of the subnet resource. |
| [`natGatewayId`](#parameter-natgatewayid) | string | The resource ID of the NAT Gateway to use for the subnet. |
| [`networkSecurityGroupId`](#parameter-networksecuritygroupid) | string | The resource ID of the network security group to assign to the subnet. |
| [`privateEndpointNetworkPolicies`](#parameter-privateendpointnetworkpolicies) | string | enable or disable apply network policies on private endpoint in the subnet. |
| [`privateLinkServiceNetworkPolicies`](#parameter-privatelinkservicenetworkpolicies) | string | enable or disable apply network policies on private link service in the subnet. |
| [`roleAssignments`](#parameter-roleassignments) | array | Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'. |
| [`routeTableId`](#parameter-routetableid) | string | The resource ID of the route table to assign to the subnet. |
| [`serviceEndpointPolicies`](#parameter-serviceendpointpolicies) | array | An array of service endpoint policies. |
| [`serviceEndpoints`](#parameter-serviceendpoints) | array | The service endpoints to enable on the subnet. |

### Parameter: `addressPrefix`

The address prefix for the subnet.
- Required: Yes
- Type: string

### Parameter: `addressPrefixes`

List of address prefixes for the subnet.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `applicationGatewayIPConfigurations`

Application gateway IP configurations of virtual network resource.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `delegations`

The delegations to enable on the subnet.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `enableDefaultTelemetry`

Enable telemetry via a Globally Unique Identifier (GUID).
- Required: No
- Type: bool
- Default: `True`

### Parameter: `ipAllocations`

Array of IpAllocation which reference this subnet.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `name`

The Name of the subnet resource.
- Required: Yes
- Type: string

### Parameter: `natGatewayId`

The resource ID of the NAT Gateway to use for the subnet.
- Required: No
- Type: string
- Default: `''`

### Parameter: `networkSecurityGroupId`

The resource ID of the network security group to assign to the subnet.
- Required: No
- Type: string
- Default: `''`

### Parameter: `privateEndpointNetworkPolicies`

enable or disable apply network policies on private endpoint in the subnet.
- Required: No
- Type: string
- Default: `''`
- Allowed:
  ```Bicep
  [
    ''
    'Disabled'
    'Enabled'
  ]
  ```

### Parameter: `privateLinkServiceNetworkPolicies`

enable or disable apply network policies on private link service in the subnet.
- Required: No
- Type: string
- Default: `''`
- Allowed:
  ```Bicep
  [
    ''
    'Disabled'
    'Enabled'
  ]
  ```

### Parameter: `roleAssignments`

Array of role assignment objects that contain the 'roleDefinitionIdOrName' and 'principalId' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: '/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11'.
- Required: No
- Type: array


| Name | Required | Type | Description |
| :-- | :-- | :--| :-- |
| [`condition`](#parameter-roleassignmentscondition) | No | string | Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container" |
| [`conditionVersion`](#parameter-roleassignmentsconditionversion) | No | string | Optional. Version of the condition. |
| [`delegatedManagedIdentityResourceId`](#parameter-roleassignmentsdelegatedmanagedidentityresourceid) | No | string | Optional. The Resource Id of the delegated managed identity resource. |
| [`description`](#parameter-roleassignmentsdescription) | No | string | Optional. The description of the role assignment. |
| [`principalId`](#parameter-roleassignmentsprincipalid) | Yes | string | Required. The principal ID of the principal (user/group/identity) to assign the role to. |
| [`principalType`](#parameter-roleassignmentsprincipaltype) | No | string | Optional. The principal type of the assigned principal ID. |
| [`roleDefinitionIdOrName`](#parameter-roleassignmentsroledefinitionidorname) | Yes | string | Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead. |

### Parameter: `roleAssignments.condition`

Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container"

- Required: No
- Type: string

### Parameter: `roleAssignments.conditionVersion`

Optional. Version of the condition.

- Required: No
- Type: string
- Allowed: `[2.0]`

### Parameter: `roleAssignments.delegatedManagedIdentityResourceId`

Optional. The Resource Id of the delegated managed identity resource.

- Required: No
- Type: string

### Parameter: `roleAssignments.description`

Optional. The description of the role assignment.

- Required: No
- Type: string

### Parameter: `roleAssignments.principalId`

Required. The principal ID of the principal (user/group/identity) to assign the role to.

- Required: Yes
- Type: string

### Parameter: `roleAssignments.principalType`

Optional. The principal type of the assigned principal ID.

- Required: No
- Type: string
- Allowed: `[Device, ForeignGroup, Group, ServicePrincipal, User]`

### Parameter: `roleAssignments.roleDefinitionIdOrName`

Required. The name of the role to assign. If it cannot be found you can specify the role definition ID instead.

- Required: Yes
- Type: string

### Parameter: `routeTableId`

The resource ID of the route table to assign to the subnet.
- Required: No
- Type: string
- Default: `''`

### Parameter: `serviceEndpointPolicies`

An array of service endpoint policies.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `serviceEndpoints`

The service endpoints to enable on the subnet.
- Required: No
- Type: array
- Default: `[]`

### Parameter: `virtualNetworkName`

The name of the parent virtual network. Required if the template is used in a standalone deployment.
- Required: Yes
- Type: string


## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the virtual network peering. |
| `resourceGroupName` | string | The resource group the virtual network peering was deployed into. |
| `resourceId` | string | The resource ID of the virtual network peering. |
| `subnetAddressPrefix` | string | The address prefix for the subnet. |
| `subnetAddressPrefixes` | array | List of address prefixes for the subnet. |

## Cross-referenced modules

_None_

## Notes

The `privateEndpointNetworkPolicies` property must be set to disabled for subnets that contain private endpoints. It confirms that NSGs rules will not apply to private endpoints (currently not supported, [reference](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview#limitations)). Default Value when not specified is "Enabled".

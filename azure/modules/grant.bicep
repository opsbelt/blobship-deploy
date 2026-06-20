// RG-scoped role assignment: grant BlobShip's service principal the
// Storage Blob Data Contributor role on one storage account (or container).

targetScope = 'resourceGroup'

@description('BlobShip app id — used only to make the role-assignment name deterministic.')
param blobshipAppId string

@description('Object id of the BlobShip service principal in this tenant.')
param blobshipPrincipalId string

@description('Storage account name (in this resource group).')
param storageAccountName string

@description('Optional container name to scope the grant to; empty = whole account.')
param containerName string = ''

// Storage Blob Data Contributor — read/write blob DATA only. No management-plane,
// no account keys. This is exactly what BlobShip needs to mint user-delegation SAS.
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing =
  if (!empty(containerName)) {
    name: '${storageAccountName}/default/${containerName}'
  }

resource grantOnAccount 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (empty(containerName)) {
    name: guid(storageAccount.id, blobshipAppId, storageBlobDataContributor)
    scope: storageAccount
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor)
      principalId: blobshipPrincipalId
      principalType: 'ServicePrincipal'
      description: 'BlobShip scoped upload broker access'
    }
  }

resource grantOnContainer 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (!empty(containerName)) {
    name: guid('${storageAccount.id}/${containerName}', blobshipAppId, storageBlobDataContributor)
    scope: container
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributor)
      principalId: blobshipPrincipalId
      principalType: 'ServicePrincipal'
      description: 'BlobShip scoped upload broker access'
    }
  }

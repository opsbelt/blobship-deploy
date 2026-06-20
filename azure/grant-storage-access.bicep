// BlobShip — one-click storage access grant (vanilla RBAC, no directory writes).
//
// The customer clicks a "Deploy to Azure" button, picks the storage account, and
// this grants BlobShip's service principal the LEAST-PRIVILEGE Storage Blob Data
// Contributor role on JUST that account (optionally one container). Revoke anytime
// by deleting the role assignment.
//
// The BlobShip service principal must already exist in the tenant (BlobShip is a
// multitenant app the customer has added). BlobShip pre-fills its object id as
// `blobshipPrincipalId`, so this template does NO directory writes — the deployer
// only needs RBAC-write (Owner / User Access Administrator) on the account.

targetScope = 'subscription'

@description('BlobShip app (client) ID — used only to make the role-assignment name stable.')
param blobshipAppId string = '833cb164-4864-496a-985d-6bace547eacc'

@description('Object id of the BlobShip service principal in THIS tenant. Pre-filled by BlobShip.')
param blobshipPrincipalId string

@description('Resource ID of the storage account to grant BlobShip scoped access to (chosen in the wizard).')
param storageAccountResourceId string

@description('Optional: limit the grant to a single blob container. Leave empty for the whole account.')
param containerName string = ''

var rgName = split(storageAccountResourceId, '/')[4]
var storageAccountName = last(split(storageAccountResourceId, '/'))

// The role assignment lives at the storage account's scope, so do it in that RG.
module grant 'modules/grant.bicep' = {
  name: 'blobship-grant-${storageAccountName}'
  scope: resourceGroup(rgName)
  params: {
    blobshipAppId: blobshipAppId
    blobshipPrincipalId: blobshipPrincipalId
    storageAccountName: storageAccountName
    containerName: containerName
  }
}

@description('Storage account the grant applies to — this is the connector Storage account.')
output storageAccount string = storageAccountName

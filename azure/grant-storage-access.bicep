// BlobShip — one-click storage access grant.
//
// The customer clicks a "Deploy to Azure" button, picks the storage account they
// want BlobShip to broker uploads into, and this grants BlobShip's service
// principal the LEAST-PRIVILEGE data role on JUST that account (optionally a
// single container). No subscription-wide access, no Lighthouse, no account keys.
// Revoke anytime by deleting the role assignment.
//
// It also resolves-or-creates BlobShip's service principal in the customer's
// tenant from BlobShip's constant app id (Microsoft Graph extension), so the
// whole grant is a single deployment — the customer never hunts for a GUID.

targetScope = 'subscription'

extension microsoftGraph

@description('BlobShip multitenant application (client) ID. Constant — pre-filled by BlobShip; do not change.')
param blobshipAppId string = '833cb164-4864-496a-985d-6bace547eacc'

@description('Resource ID of the storage account to grant BlobShip scoped access to (chosen in the wizard).')
param storageAccountResourceId string

@description('Optional: limit the grant to a single blob container. Leave empty to scope to the whole account.')
param containerName string = ''

// Storage account id format: /subscriptions/{s}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}
var rgName = split(storageAccountResourceId, '/')[4]
var storageAccountName = last(split(storageAccountResourceId, '/'))

// Resolve BlobShip's service principal in THIS tenant by its app id (creates it
// if the BlobShip app has not been added to the tenant yet).
resource blobshipSp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: blobshipAppId
}

// The role assignment lives at the storage account's scope, so do it in that RG.
module grant 'modules/grant.bicep' = {
  name: 'blobship-grant-${storageAccountName}'
  scope: resourceGroup(rgName)
  params: {
    blobshipAppId: blobshipAppId
    blobshipPrincipalId: blobshipSp.id
    storageAccountName: storageAccountName
    containerName: containerName
  }
}

@description('Object id BlobShip was granted in this tenant.')
output blobshipPrincipalId string = blobshipSp.id
@description('Tenant the grant was created in — this is the connector Tenant ID.')
output tenantId string = tenant().tenantId
@description('Storage account the grant applies to — this is the connector Storage account.')
output storageAccount string = storageAccountName

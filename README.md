# blobship-deploy

Public, customer-facing **one-click deployment templates** for BlobShip onboarding.
This repo is intentionally **public** because Azure's "Deploy to Azure" button fetches
templates from an unauthenticated raw HTTPS URL — it can't read a private repo.

> Contains no secrets — only ARM/Bicep that grants BlobShip **least-privilege**,
> revocable access to a customer's own cloud storage. BlobShip's source lives in the
> private `opsbelt/blobship` repo.

## `azure/` — one-click Azure Storage access grant

The slick equivalent of a Lighthouse onboarding link, but scoped to a **single
storage account** instead of a whole subscription. In one deployment the customer:
- has BlobShip's service principal **resolved-or-created** in their tenant from our
  constant app id (Microsoft Graph Bicep extension) — no GUID hunting, no separate
  consent step, and
- gets one **`Storage Blob Data Contributor`** role assignment on the storage account
  they pick (optionally a single container). No subscription access, no account keys.
  Revoke = delete that one role assignment.

| File | Purpose |
|---|---|
| `azure/grant-storage-access.bicep` | source of truth (subscription-scoped) |
| `azure/modules/grant.bicep` | the RG-scoped role assignment |
| `azure/mainTemplate.json` | **compiled** ARM the button points at |
| `azure/createUiDefinition.json` | portal wizard: pick the storage account (+ optional container) |
| `azure/deploy-url.mjs` | prints the Deploy-to-Azure button URL |

### Fill the app id, then recompile
Set BlobShip's **multitenant** app (client) id as the `blobshipAppId` default in
`azure/grant-storage-access.bicep`, then:
```bash
cd azure && az bicep build --file grant-storage-access.bicep --outfile mainTemplate.json
```
(The app must be **multitenant** so its SP can land in customer tenants — a
single-tenant test app only grants in your own tenant.)

### The button URL
```bash
node azure/deploy-url.mjs https://raw.githubusercontent.com/opsbelt/blobship-deploy/main/azure
```
→ `https://portal.azure.com/#create/Microsoft.Template/uri/<enc>/createUIDefinitionUri/<enc>`

### ⚠️ Portal vs CLI
The template uses the **Microsoft Graph Bicep extension** (`languageVersion
2.x-experimental`) so the SP is resolved in one shot. Portal custom-deploy support for
Graph resources is newer — **smoke-test the button on your own tenant first.** The CLI
path is fully supported:
```bash
cd azure && az deployment sub create \
  --location uksouth \
  --template-file mainTemplate.json \
  --parameters storageAccountResourceId="<storage account resource id>"
# add: containerName="uploads"   to scope to one container
```
If you need zero-caveat portal support, the fallback is to drop the Graph extension,
take `principalId` as a parameter, and have BlobShip inject it into a per-customer link
after a one-time admin-consent.

### After the grant
The deployment outputs `tenantId` and `storageAccount` — exactly the **Tenant ID** and
**Storage account** fields on the BlobShip connector. Create the connector with those,
hit **Test**, and the upload path is live.

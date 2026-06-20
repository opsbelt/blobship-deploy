#!/usr/bin/env node
// Build the "Deploy to Azure" button URL for the BlobShip storage-access template.
//
// Usage:
//   node deploy-url.mjs <base-url-where-the-json-files-are-hosted>
// e.g.
//   node deploy-url.mjs https://raw.githubusercontent.com/opsbelt/blobship/main/infra/azure-onboarding

const base = process.argv[2];
if (!base) {
  console.error('usage: node deploy-url.mjs <base-url-hosting mainTemplate.json + createUiDefinition.json>');
  process.exit(1);
}
const trimmed = base.replace(/\/+$/, '');
const main = encodeURIComponent(`${trimmed}/mainTemplate.json`);
const ui = encodeURIComponent(`${trimmed}/createUiDefinition.json`);
const url = `https://portal.azure.com/#create/Microsoft.Template/uri/${main}/createUIDefinitionUri/${ui}`;
console.log(url);

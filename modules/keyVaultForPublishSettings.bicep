// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the Key Vault.')
param keyVaultName string

@description('Optional. Azure region for deployment.')
param location string = resourceGroup().location

@description('Required. The name of the App Service to get publish settings from.')
param appServiceName string

@description('Optional. Whether to create a new Key Vault or use an existing one.')
param createNewKeyVault bool = true

@description('Required. Resource tags.')
param tags object

// ============ //
// Resources    //
// ============ //

// Conditionally create Key Vault for storing publish settings
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.keyvault/vaults
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (createNewKeyVault) {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    accessPolicies: []
  }
}

// Reference existing Key Vault if not creating new
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (!createNewKeyVault) {
  name: keyVaultName
}

// Reference existing App Service to get publish profile
resource appService 'Microsoft.Web/sites@2023-12-01' existing = {
  name: appServiceName
}

// Store the App Service default hostname as a secret in a new Key Vault
resource publishSettingsSecretNew 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (createNewKeyVault) {
  parent: keyVault
  name: '${appServiceName}-publish-url'
  properties: {
    value: 'https://${appService.properties.defaultHostName}'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store the App Service default hostname as a secret in an existing Key Vault
resource publishSettingsSecretExisting 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = if (!createNewKeyVault) {
  parent: existingKeyVault
  name: '${appServiceName}-publish-url'
  properties: {
    value: 'https://${appService.properties.defaultHostName}'
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The Key Vault name used.')
output keyVaultName string = createNewKeyVault ? keyVault.name : existingKeyVault.name

@description('The Key Vault resource ID.')
output keyVaultResourceId string = createNewKeyVault ? keyVault.id : existingKeyVault.id

@description('The secret name for publish settings.')
output publishSettingsSecretName string = createNewKeyVault ? publishSettingsSecretNew.name : publishSettingsSecretExisting.name

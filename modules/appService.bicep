// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the App Service / Function App.')
param appName string

@description('Optional. Azure region for deployment.')
param location string = resourceGroup().location

@description('Required. The resource ID of the App Service Plan.')
param appServicePlanId string

@description('Required. The kind of application to deploy.')
@allowed([
  'WebApp'
  'FunctionApp'
])
param appKind string

@description('Required. The runtime stack for the application.')
@allowed([
  'dotnet|v8.0'
  'dotnet|v6.0'
  'node|20-lts'
  'node|18-lts'
  'python|3.12'
  'python|3.11'
  'python|3.10'
  'java|17-java17'
  'java|11-java11'
  'php|8.3'
  'DOTNET|8.0'
  'DOTNET|6.0'
  'DOTNET-ISOLATED|8.0'
  'NODE|20'
  'NODE|18'
  'PYTHON|3.12'
  'PYTHON|3.11'
  'JAVA|17'
  'JAVA|11'
])
param runtimeStack string

@description('Optional. Enable HTTPS only. Always true for security.')
param httpsOnly bool = true

@description('Optional. Enable system-assigned managed identity.')
param enableSystemIdentity bool = true

@description('Optional. User-assigned managed identity resource IDs.')
param userAssignedIdentities object = {}

@description('Optional. App settings key-value pairs.')
param appSettings array = []

@description('Optional. Site configuration object.')
param siteConfig object = {}

@description('Optional. Enable VNet integration.')
param vnetIntegration bool = true

@description('Optional. Subnet resource ID for VNet integration. Required if vnetIntegration is true.')
param vnetSubnetId string = ''

@description('Required. Resource tags.')
param tags object

// ============ //
// Variables    //
// ============ //

// Determine the kind property for the web app resource
var webAppKind = appKind == 'FunctionApp' ? 'functionapp,linux' : 'app,linux'

// Build identity configuration based on params
var hasUserIdentities = !empty(userAssignedIdentities)
var identityType = enableSystemIdentity && hasUserIdentities ? 'SystemAssigned, UserAssigned' : enableSystemIdentity ? 'SystemAssigned' : hasUserIdentities ? 'UserAssigned' : 'None'

var identity = identityType == 'None' ? null : {
  type: identityType
  userAssignedIdentities: hasUserIdentities ? userAssignedIdentities : null
}

// Parse runtime: e.g., 'dotnet|v8.0' => linuxFxVersion = 'DOTNET|8.0'
var linuxFxVersion = runtimeStack

// Merge site configuration with runtime settings
var mergedSiteConfig = union(siteConfig, {
  linuxFxVersion: linuxFxVersion
  ftpsState: 'Disabled'
  minTlsVersion: '1.2'
  http20Enabled: true
  alwaysOn: true
})

// Build app settings array with function-specific settings
var baseAppSettings = appKind == 'FunctionApp' ? [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: split(runtimeStack, '|')[0]
  }
] : []

var mergedAppSettings = concat(baseAppSettings, appSettings)

// ============ //
// Resources    //
// ============ //

// Deploy App Service / Function App
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.web/sites
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appName
  location: location
  kind: webAppKind
  tags: tags
  identity: identity
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: httpsOnly
    siteConfig: mergedSiteConfig
    virtualNetworkSubnetId: vnetIntegration && !empty(vnetSubnetId) ? vnetSubnetId : null
  }
}

// Deploy App Settings
resource appSettingsConfig 'Microsoft.Web/sites/config@2023-12-01' = if (!empty(mergedAppSettings)) {
  parent: appService
  name: 'appsettings'
  properties: reduce(mergedAppSettings, {}, (cur, next) => union(cur, { '${next.name}': next.value }))
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the app service.')
output resourceId string = appService.id

@description('The name of the app service.')
output name string = appService.name

@description('The default hostname of the app service.')
output defaultHostname string = appService.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity.')
output systemAssignedPrincipalId string = enableSystemIdentity ? appService.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = appService.location

@description('The resource group the app was deployed into.')
output resourceGroupName string = resourceGroup().name

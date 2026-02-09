metadata name = 'AppServices Module'
metadata description = 'Deploys Azure App Service (WebApp or FunctionApp) with App Service Plan, managed identity, VNet integration, and enterprise security defaults!'
metadata owner = 'cloudgeeklabs'
metadata version = '1.0.0'

targetScope = 'resourceGroup'

// ============ //
// Parameters   //
// ============ //

@description('Required. Workload name used to generate resource names. Max 10 characters, lowercase letters and numbers only.')
@minLength(2)
@maxLength(10)
param workloadName string

@description('Optional. Azure region for deployment. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Optional. Environment identifier (dev, test, prod). Used in naming and tagging.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Required. SKU for the App Service Plan.')
@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
  'P0v3'
  'Y1'
  'EP1'
  'EP2'
  'EP3'
])
param sku string

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

@description('Optional. Use an existing App Service Plan resource ID instead of creating a new one.')
param existingAppServicePlanId string = ''

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

@description('Optional. Enable private endpoint.')
param enablePrivateEndpoint bool = false

@description('Optional. Subnet resource ID for private endpoint. Required if enablePrivateEndpoint is true.')
param privateEndpointSubnetId string = ''

@description('Optional. Key Vault name for storing publish settings. If empty, a new Key Vault will be created.')
param existingKeyVaultName string = ''

@description('Optional. Log Analytics workspace ID for diagnostics. Uses default if not specified.')
param diagnosticWorkspaceId string = ''

@description('Optional. Enable diagnostic settings.')
param enableDiagnostics bool = true

@description('Optional. Enable resource lock to prevent deletion.')
param enableLock bool = true

@description('Optional. Lock level to apply if enabled.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param lockLevel string = 'CanNotDelete'

@description('Optional. RBAC role assignments for the App Service.')
param roleAssignments roleAssignmentType[] = []

@description('Required. Resource tags for organization and cost management.')
param tags object

// ============ //
// Variables    //
// ============ //

// Generate unique suffix using resource group ID to ensure uniqueness
var uniqueSuffix = take(uniqueString(resourceGroup().id, subscription().id), 5)

// Construct resource names
var appServicePlanName = 'asp-${toLower(workloadName)}-${environment}-${uniqueSuffix}'
var appName = 'app-${toLower(workloadName)}-${environment}-${uniqueSuffix}'
var keyVaultName = !empty(existingKeyVaultName) ? existingKeyVaultName : 'kv-${toLower(workloadName)}-${take(uniqueSuffix, 4)}'

// Determine if we need to create a new App Service Plan
var createNewPlan = empty(existingAppServicePlanId)

// Map appKind to plan kind
var planKind = appKind == 'FunctionApp' ? 'FunctionApp' : 'Linux'

// Default Log Analytics workspace for diagnostics if not provided
var defaultWorkspaceId = '/subscriptions/b18ea7d6-14b5-41f3-a00d-804a5180c589/resourceGroups/msft-core-observability/providers/Microsoft.OperationalInsights/workspaces/msft-core-cus-law'

// Merge provided workspace ID with default using conditional logic
var mergedWorkspaceId = !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : defaultWorkspaceId

// ============ //
// Resources    //
// ============ //

// Deploy App Service Plan (if not using existing)
module appServicePlan 'modules/appServicePlan.bicep' = if (createNewPlan) {
  name: '${uniqueString(deployment().name, location)}-app-service-plan'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: sku
    planKind: planKind
    tags: tags
  }
}

// Deploy App Service / Function App
module appService 'modules/appService.bicep' = {
  name: '${uniqueString(deployment().name, location)}-app-service'
  params: {
    appName: appName
    location: location
    appServicePlanId: createNewPlan ? (appServicePlan.?outputs.resourceId ?? '') : existingAppServicePlanId
    appKind: appKind
    runtimeStack: runtimeStack
    httpsOnly: httpsOnly
    enableSystemIdentity: enableSystemIdentity
    userAssignedIdentities: userAssignedIdentities
    appSettings: appSettings
    siteConfig: siteConfig
    vnetIntegration: vnetIntegration
    vnetSubnetId: vnetSubnetId
    tags: tags
  }
}

// Deploy Key Vault for publish settings (create new if not using existing)
module keyVault 'modules/keyVaultForPublishSettings.bicep' = {
  name: '${uniqueString(deployment().name, location)}-key-vault'
  params: {
    keyVaultName: keyVaultName
    location: location
    appServiceName: appService.?outputs.name ?? ''
    createNewKeyVault: empty(existingKeyVaultName)
    tags: tags
  }
}

// Deploy Private Endpoint if enabled
module privateEndpoint 'modules/privateEndpoint.bicep' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: '${uniqueString(deployment().name, location)}-private-endpoint'
  params: {
    appServiceName: appService.?outputs.name ?? ''
    appServiceResourceId: appService.?outputs.resourceId ?? ''
    subnetResourceId: privateEndpointSubnetId
    location: location
    privateEndpointName: '${appName}-pe'
    tags: tags
  }
}

// Deploy Diagnostic Settings
module diagnostics 'modules/diagnostics.bicep' = if (enableDiagnostics) {
  name: '${uniqueString(deployment().name, location)}-diagnostics'
  params: {
    appServiceName: appService.?outputs.name ?? ''
    workspaceId: mergedWorkspaceId
    enableLogs: true
    enableMetrics: true
  }
}

// Deploy Resource Lock to prevent accidental deletion
module lock 'modules/lock.bicep' = if (enableLock) {
  name: '${uniqueString(deployment().name, location)}-lock'
  params: {
    appServiceName: appService.?outputs.name ?? ''
    lockLevel: lockLevel
    lockNotes: 'Prevents accidental deletion of ${environment} App Service for ${workloadName}'
  }
}

// Deploy RBAC Role Assignments
module rbac 'modules/rbac.bicep' = if (!empty(roleAssignments)) {
  name: '${uniqueString(deployment().name, location)}-rbac'
  params: {
    appServiceName: appService.?outputs.name ?? ''
    roleAssignments: roleAssignments
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the App Service.')
output resourceId string = appService.?outputs.resourceId ?? ''

@description('The name of the App Service.')
output name string = appService.?outputs.name ?? ''

@description('The default hostname of the App Service.')
output defaultHostname string = appService.?outputs.defaultHostname ?? ''

@description('The principal ID of the system-assigned managed identity.')
output systemAssignedPrincipalId string = appService.?outputs.systemAssignedPrincipalId ?? ''

@description('The resource group the App Service was deployed into.')
output resourceGroupName string = appService.?outputs.resourceGroupName ?? ''

@description('The location the resource was deployed into.')
output location string = appService.?outputs.location ?? ''

@description('The App Service Plan resource ID.')
output appServicePlanId string = createNewPlan ? (appServicePlan.?outputs.resourceId ?? '') : existingAppServicePlanId

@description('The generated app name.')
output appName string = appName

@description('The Key Vault name used for secrets.')
output keyVaultName string = keyVaultName

@description('The environment identifier.')
output environment string = environment

@description('The unique naming suffix generated.')
output uniqueSuffix string = uniqueSuffix

// ============== //
// Type Definitions //
// ============== //

@description('Role assignment configuration type.')
type roleAssignmentType = {
  @description('The principal ID (object ID) of the identity.')
  principalId: string

  @description('The role definition ID or built-in role name.')
  roleDefinitionIdOrName: string

  @description('The type of principal.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ManagedIdentity')?
}

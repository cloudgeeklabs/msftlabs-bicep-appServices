// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the App Service Plan.')
param appServicePlanName string

@description('Optional. Azure region for deployment.')
param location string = resourceGroup().location

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

@description('Required. The kind of App Service Plan.')
@allowed([
  'Windows'
  'Linux'
  'FunctionApp'
])
param planKind string

@description('Required. Resource tags.')
param tags object

// ============ //
// Variables    //
// ============ //

// Map planKind to the App Service Plan 'kind' property
var kindMap = {
  Windows: 'app'
  Linux: 'linux'
  FunctionApp: 'functionapp'
}

// Determine if plan is Linux-based (reserved property must be true for Linux)
var isLinux = planKind == 'Linux' || planKind == 'FunctionApp'

// ============ //
// Resources    //
// ============ //

// Deploy App Service Plan
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.web/serverfarms
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: kindMap[planKind]
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    reserved: isLinux
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the App Service Plan.')
output resourceId string = appServicePlan.id

@description('The name of the App Service Plan.')
output name string = appServicePlan.name

@description('The location the resource was deployed into.')
output location string = appServicePlan.location

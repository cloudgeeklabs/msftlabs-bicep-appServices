// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the App Service to configure diagnostics for.')
param appServiceName string

@description('Required. Resource ID of the Log Analytics workspace.')
param workspaceId string

@description('Optional. The name of the diagnostic setting.')
param diagnosticSettingName string = '${appServiceName}-diagnostics'

@description('Optional. Enable application logs.')
param enableLogs bool = true

@description('Optional. Enable metrics collection.')
param enableMetrics bool = true

// ============ //
// Variables    //
// ============ //

// Log categories for App Service
var logsConfig = [
  {
    category: 'AppServiceHTTPLogs'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
  {
    category: 'AppServiceConsoleLogs'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
  {
    category: 'AppServiceAppLogs'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
  {
    category: 'AppServicePlatformLogs'
    enabled: enableLogs
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
]

// Metrics configuration
var metricsConfig = [
  {
    category: 'AllMetrics'
    enabled: enableMetrics
    retentionPolicy: {
      enabled: false
      days: 0
    }
  }
]

// ============ //
// Resources    //
// ============ //

// Reference existing App Service
resource appService 'Microsoft.Web/sites@2023-12-01' existing = {
  name: appServiceName
}

// Deploy diagnostic settings for App Service
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.insights/diagnosticsettings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: appService
  properties: {
    workspaceId: workspaceId
    logs: logsConfig
    metrics: metricsConfig
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the diagnostic setting.')
output resourceId string = diagnosticSettings.id

@description('The name of the diagnostic setting.')
output name string = diagnosticSettings.name

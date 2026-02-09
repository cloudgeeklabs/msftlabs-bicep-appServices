// ============ //
// Parameters   //
// ============ //

@description('Required. The name of the App Service to lock.')
param appServiceName string

@description('Optional. The lock level to apply.')
@allowed([
  'CanNotDelete'
  'ReadOnly'
])
param lockLevel string = 'CanNotDelete'

@description('Optional. Notes describing why the lock was applied.')
param lockNotes string = 'Prevents accidental deletion of production App Service.'

// ============ //
// Resources    //
// ============ //

// Reference existing App Service
resource appService 'Microsoft.Web/sites@2023-12-01' existing = {
  name: appServiceName
}

// Apply resource lock to App Service
// MSLearn: https://learn.microsoft.com/azure/templates/microsoft.authorization/locks
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${appServiceName}-lock'
  scope: appService
  properties: {
    level: lockLevel
    notes: lockNotes
  }
}

// ============ //
// Outputs      //
// ============ //

@description('The resource ID of the lock.')
output resourceId string = lock.id

@description('The name of the lock.')
output name string = lock.name

@description('The lock level applied.')
output level string = lock.properties.level

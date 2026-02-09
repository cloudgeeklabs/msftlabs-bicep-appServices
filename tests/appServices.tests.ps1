#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }

BeforeAll {
    $script:ModulePath = Split-Path -Parent $PSScriptRoot
    $script:TemplatePath = Join-Path $script:ModulePath "main.bicep"
    $script:ParametersPath = Join-Path $PSScriptRoot "test.parameters.json"
}

Describe "Bicep Module: App Services" {
    
    Context "Static Analysis" {
        
        It "Should have valid Bicep syntax" {
            az bicep build --file $script:TemplatePath 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }
        
        It "Should generate ARM template" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            Test-Path $armTemplatePath | Should -Be $true
        }
        
        It "Should require HTTPS only" {
            $content = Get-Content $script:TemplatePath -Raw
            $content | Should -Match "httpsOnly.*true"
        }
        
        It "Should support managed identity" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/appService.bicep") -Raw
            $moduleContent | Should -Match "enableSystemIdentity"
            $moduleContent | Should -Match "SystemAssigned"
            $moduleContent | Should -Match "UserAssigned"
        }
        
        It "Should enforce TLS 1.2 minimum" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/appService.bicep") -Raw
            $moduleContent | Should -Match "minTlsVersion.*1.2"
        }
        
        It "Should disable FTPS" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/appService.bicep") -Raw
            $moduleContent | Should -Match "ftpsState.*Disabled"
        }

        It "Should support VNet integration" {
            $moduleContent = Get-Content (Join-Path $script:ModulePath "modules/appService.bicep") -Raw
            $moduleContent | Should -Match "virtualNetworkSubnetId"
            $moduleContent | Should -Match "vnetIntegration"
        }

        It "Should have allowed values for appKind" {
            $content = Get-Content $script:TemplatePath -Raw
            $content | Should -Match "WebApp"
            $content | Should -Match "FunctionApp"
        }

        It "Should have allowed values for sku" {
            $content = Get-Content $script:TemplatePath -Raw
            $content | Should -Match "B1"
            $content | Should -Match "S1"
            $content | Should -Match "P1v3"
        }

        It "Should have private endpoint module" {
            $pePath = Join-Path $script:ModulePath "modules/privateEndpoint.bicep"
            Test-Path $pePath | Should -Be $true
        }

        It "Should have Key Vault integration for publish settings" {
            $kvPath = Join-Path $script:ModulePath "modules/keyVaultForPublishSettings.bicep"
            Test-Path $kvPath | Should -Be $true
        }
    }
    
    Context "Template Validation" {
        
        It "Should have valid ARM template schema" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.'$schema' | Should -Not -BeNullOrEmpty
            $template.resources | Should -Not -BeNullOrEmpty
        }
        
        It "Should define app service module deployment" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $moduleDeployments = $template.resources[0].PSObject.Properties | Where-Object {
                $_.Value.type -eq "Microsoft.Resources/deployments"
            }
            
            $moduleDeployments | Should -Not -BeNullOrEmpty
        }
        
        It "Should have required parameters defined" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.parameters.workloadName | Should -Not -BeNullOrEmpty
            $template.parameters.sku | Should -Not -BeNullOrEmpty
            $template.parameters.appKind | Should -Not -BeNullOrEmpty
            $template.parameters.runtimeStack | Should -Not -BeNullOrEmpty
            $template.parameters.tags | Should -Not -BeNullOrEmpty
        }
        
        It "Should have outputs defined" {
            $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
            $template = Get-Content $armTemplatePath | ConvertFrom-Json
            
            $template.outputs | Should -Not -BeNullOrEmpty
            $template.outputs.resourceId | Should -Not -BeNullOrEmpty
            $template.outputs.defaultHostname | Should -Not -BeNullOrEmpty
        }

        It "Should have diagnostic settings module" {
            $diagPath = Join-Path $script:ModulePath "modules/diagnostics.bicep"
            Test-Path $diagPath | Should -Be $true
        }

        It "Should have lock module" {
            $lockPath = Join-Path $script:ModulePath "modules/lock.bicep"
            Test-Path $lockPath | Should -Be $true
        }

        It "Should have RBAC module" {
            $rbacPath = Join-Path $script:ModulePath "modules/rbac.bicep"
            Test-Path $rbacPath | Should -Be $true
        }
    }
}

AfterAll {
    $armTemplatePath = $script:TemplatePath -replace '\.bicep$', '.json'
    if (Test-Path $armTemplatePath) {
        # Optionally remove: Remove-Item $armTemplatePath -Force
    }
}

# App Services Bicep Module

A production-ready Azure Bicep module for deploying App Services (WebApp or FunctionApp) with managed identity, VNet integration, and enterprise security defaults.

## Table of Contents

- [Features](#features)
- [Module Information](#module-information)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Parameters](#parameters)
- [Outputs](#outputs)
- [Testing](#testing)
- [CI/CD Workflows](#cicd-workflows)

## Features

- **WebApp & FunctionApp**: Support for both application kinds
- **App Service Plan**: Create new or use existing plan
- **Runtime Stacks**: Multiple runtimes (dotnet, node, python, java, php)
- **HTTPS Only**: Enforced by default
- **Managed Identity**: System and/or User-Assigned identity support
- **VNet Integration**: Default enabled with subnet configuration
- **Private Endpoints**: Optional private endpoint configuration
- **Key Vault Integration**: Automatic publish settings storage
- **Diagnostics Integration**: Automatic Log Analytics workspace integration
- **Resource Locking**: CanNotDelete lock to prevent accidental deletion
- **RBAC Support**: Built-in role assignment configuration
- **Security Defaults**: TLS 1.2, FTPS disabled, HTTP/2 enabled
- **CI/CD Ready**: Automated testing and ACR deployment workflows

## Module Information

- **Module Name**: `appservices`
- **Description**: Deploys Azure App Service with managed identity, VNet integration, and enterprise security defaults
- **ACR Registry**: `msftlabsbicepmods.azurecr.io`
- **Module Path**: `bicep/modules`
- **Current Version**: 1.0.0

## Prerequisites

- Azure CLI 2.50.0 or later
- Bicep CLI 0.20.0 or later
- PowerShell 7.0 or later (for Pester tests)
- Pester 5.0.0 or later (for unit testing)

## Quick Start

### Using the Module from ACR

```bicep
module appService 'br:msftlabsbicepmods.azurecr.io/bicep/modules/appservices:1.0.0' = {
  name: 'appServiceDeployment'
  params: {
    workloadName: 'myapp'
    sku: 'P1v3'
    appKind: 'WebApp'
    runtimeStack: 'dotnet|v8.0'
    tags: {
      Environment: 'Production'
      ManagedBy: 'Bicep'
    }
  }
}
```

### Deploy

```bash
az deployment group create \
  --resource-group rg-production \
  --template-file main.bicep \
  --name appservice-deployment
```

## Parameters

| Parameter       | Type   | Default | Required | Description                  |
| --------------- | ------ | ------- | -------- | ---------------------------- |
| `workloadName`  | string | -       | Yes      | Workload name (max 10 chars) |
| `sku`           | string | -       | Yes      | App Service Plan SKU         |
| `appKind`       | string | -       | Yes      | WebApp or FunctionApp        |
| `runtimeStack`  | string | -       | Yes      | Runtime stack                |
| `tags`          | object | -       | Yes      | Resource tags                |

## Outputs

| Output             | Type   | Description                    |
| ------------------ | ------ | ------------------------------ |
| `resourceId`       | string | App Service resource ID        |
| `name`             | string | App Service name               |
| `defaultHostname`  | string | App Service default hostname   |
| `appServicePlanId` | string | App Service Plan resource ID   |
| `environment`      | string | Environment identifier         |
| `uniqueSuffix`     | string | Generated unique naming suffix |

## Testing

```powershell
Invoke-Pester -Path ./tests -Output Detailed
```

## CI/CD Workflows

- **static-test.yaml**: Bicep syntax validation
- **unit-tests.yaml**: Pester unit test execution
- **deploy-module.yaml**: Publish to Azure Container Registry

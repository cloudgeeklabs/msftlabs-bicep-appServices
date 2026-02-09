# Changelog

All notable changes to this Bicep module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Custom domain and SSL bindings
- Application Insights integration
- Deployment slots support
- Auto-scaling rules configuration

## [1.0.0] - 2026-02-08

### Added

- Initial release of App Services module
- Support for WebApp and FunctionApp kinds
- App Service Plan creation or use existing
- Multiple runtime stack support (dotnet, node, python, java, php)
- SKU selection with allowedValues validation
- HTTPS only enforcement
- Managed Identity (System and User-Assigned)
- Site configuration with app settings
- VNet integration support (default enabled)
- Private endpoint configuration support
- Key Vault integration for publish settings (new or existing)
- Diagnostic settings with Log Analytics workspace integration
- Default workspace fallback configuration
- Resource lock (CanNotDelete) implementation
- RBAC role assignment support
- TLS 1.2 enforcement
- FTPS disabled by default
- HTTP/2 enabled
- Always On enabled
- Comprehensive tagging support

### Testing

- Pester 5.x unit tests with full module validation
- Native Bicep build and what-if testing
- PSRule analysis for Azure best practices
- Test parameters and configuration files

### CI/CD

- Static analysis workflow (static-test.yaml)
- Unit testing workflow using Pester (unit-tests.yaml)
- Automated ACR deployment workflow (deploy-module.yaml)
- GitHub Actions integration with test result publishing

### Security

- HTTPS only enforced
- TLS 1.2 minimum version
- FTPS disabled
- Managed Identity enabled by default
- VNet integration default enabled
- Private endpoint support

### Documentation

- Comprehensive README with usage examples
- Testing documentation and guidelines
- CI/CD workflow documentation

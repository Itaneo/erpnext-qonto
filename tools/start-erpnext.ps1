#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Starts ERPNext Docker containers

.DESCRIPTION
    Starts previously created ERPNext containers.

.EXAMPLE
    .\start-erpnext.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DockerComposeFile = Join-Path $ProjectRoot "docker-compose.yml"

if (!(Test-Path $DockerComposeFile)) {
    Write-Host "✗ docker-compose.yml not found. Please run setup-erpnext-docker.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host "Starting ERPNext containers..." -ForegroundColor Cyan
docker-compose -f $DockerComposeFile start

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Containers started successfully" -ForegroundColor Green
    Write-Host "`nAccess ERPNext at: http://localhost:8080" -ForegroundColor Cyan
} else {
    Write-Host "✗ Failed to start containers" -ForegroundColor Red
    exit 1
}


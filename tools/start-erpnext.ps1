#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Starts ERPNext Docker containers

.DESCRIPTION
    Starts ERPNext containers using frappe_docker/pwd.yml for production.

.PARAMETER FrappeDockerPath
    Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)

.EXAMPLE
    .\start-erpnext.ps1
    
.EXAMPLE
    .\start-erpnext.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "D:\ErpNext\frappe_docker"
)

$ErrorActionPreference = "Stop"

# Check frappe_docker exists
if (!(Test-Path $FrappeDockerPath)) {
    Write-Host "✗ frappe_docker not found at: $FrappeDockerPath" -ForegroundColor Red
    Write-Host "  Clone it with: git clone https://github.com/frappe/frappe_docker $FrappeDockerPath" -ForegroundColor Yellow
    exit 1
}

# Check pwd.yml exists
$PwdYmlPath = Join-Path $FrappeDockerPath "pwd.yml"
if (!(Test-Path $PwdYmlPath)) {
    Write-Host "✗ pwd.yml not found at: $PwdYmlPath" -ForegroundColor Red
    Write-Host "  Make sure frappe_docker is up to date" -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting ERPNext containers (using pwd.yml)..." -ForegroundColor Cyan

Push-Location $FrappeDockerPath
try {
    docker compose -f pwd.yml start

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Containers started successfully" -ForegroundColor Green
        Write-Host "`nAccess ERPNext at: http://localhost:8080" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Failed to start containers" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}


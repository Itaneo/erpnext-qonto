#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View ERPNext Docker container logs

.DESCRIPTION
    Shows logs from ERPNext containers using frappe_docker/pwd.yml.

.PARAMETER FrappeDockerPath
    Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)

.PARAMETER Service
    Specific service to show logs for (e.g., backend, frontend, db)

.PARAMETER Follow
    Follow log output (like tail -f)

.PARAMETER Lines
    Number of lines to show from the end of logs (default: 100)

.EXAMPLE
    .\logs-erpnext.ps1
    
.EXAMPLE
    .\logs-erpnext.ps1 -Service backend -Follow
    
.EXAMPLE
    .\logs-erpnext.ps1 -Lines 500 -FrappeDockerPath "D:\Custom\frappe_docker"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "D:\ErpNext\frappe_docker",
    
    [Parameter(Mandatory=$false)]
    [string]$Service,
    
    [Parameter(Mandatory=$false)]
    [switch]$Follow,
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 100
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

$composeArgs = @("-f", "pwd.yml", "logs", "--tail=$Lines")

if ($Follow) {
    $composeArgs += "-f"
}

if ($Service) {
    $composeArgs += $Service
    Write-Host "Showing logs for: $Service (using pwd.yml)" -ForegroundColor Cyan
} else {
    Write-Host "Showing logs for all services (using pwd.yml)" -ForegroundColor Cyan
}

Write-Host "Press Ctrl+C to exit`n" -ForegroundColor Yellow

Push-Location $FrappeDockerPath
try {
    docker compose @composeArgs
} finally {
    Pop-Location
}


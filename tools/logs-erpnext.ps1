#!/usr/bin/env pwsh
<#
.SYNOPSIS
    View ERPNext Docker container logs

.DESCRIPTION
    Shows logs from ERPNext containers with optional filtering by service.

.PARAMETER Service
    Specific service to show logs for (e.g., backend, frontend, mariadb)

.PARAMETER Follow
    Follow log output (like tail -f)

.PARAMETER Lines
    Number of lines to show from the end of logs (default: 100)

.EXAMPLE
    .\logs-erpnext.ps1
    
.EXAMPLE
    .\logs-erpnext.ps1 -Service backend -Follow
    
.EXAMPLE
    .\logs-erpnext.ps1 -Lines 500
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Service,
    
    [Parameter(Mandatory=$false)]
    [switch]$Follow,
    
    [Parameter(Mandatory=$false)]
    [int]$Lines = 100
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DockerComposeFile = Join-Path $ProjectRoot "docker-compose.yml"

if (!(Test-Path $DockerComposeFile)) {
    Write-Host "✗ docker-compose.yml not found. Please run setup-erpnext-docker.ps1 first." -ForegroundColor Red
    exit 1
}

$composeArgs = @("-f", $DockerComposeFile, "logs", "--tail=$Lines")

if ($Follow) {
    $composeArgs += "-f"
}

if ($Service) {
    $composeArgs += $Service
    Write-Host "Showing logs for: $Service" -ForegroundColor Cyan
} else {
    Write-Host "Showing logs for all services" -ForegroundColor Cyan
}

Write-Host "Press Ctrl+C to exit`n" -ForegroundColor Yellow

docker-compose @composeArgs


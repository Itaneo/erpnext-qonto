#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Opens a shell in ERPNext backend container

.DESCRIPTION
    Opens an interactive bash shell in the ERPNext backend container
    for executing bench commands and debugging.

.PARAMETER Command
    Execute a specific command instead of opening interactive shell

.EXAMPLE
    .\shell-erpnext.ps1
    
.EXAMPLE
    .\shell-erpnext.ps1 -Command "bench --site erpnext.local migrate"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Command
)

$ErrorActionPreference = "Stop"

# Try to find backend container (works for both production and development)
$ProjectName = (Split-Path -Parent $PSScriptRoot | Split-Path -Leaf) -replace '[^a-z0-9]', ''
$PossibleNames = @(
    "${ProjectName}-backend-1",
    "erpnext-qonto-backend-1",
    "erpnext-backend",
    "backend"
)

$ContainerName = $null
foreach ($name in $PossibleNames) {
    $running = docker ps --filter "name=$name" --format "{{.Names}}" 2>$null
    if ($running) {
        $ContainerName = $running
        break
    }
}

if (-not $ContainerName) {
    Write-Host "✗ Backend container not running" -ForegroundColor Red
    Write-Host "  Available containers:" -ForegroundColor Yellow
    docker ps --format "table {{.Names}}\t{{.Status}}"
    Write-Host "`n  Start containers with: .\start-erpnext.ps1" -ForegroundColor Yellow
    exit 1
}

if ($Command) {
    Write-Host "Executing command in $ContainerName..." -ForegroundColor Cyan
    docker exec -it $ContainerName bash -c $Command
} else {
    Write-Host "Opening shell in $ContainerName..." -ForegroundColor Cyan
    Write-Host "Tip: Use 'bench --help' to see available commands" -ForegroundColor Yellow
    Write-Host ""
    docker exec -it $ContainerName bash
}


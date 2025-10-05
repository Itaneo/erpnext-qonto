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
$ContainerName = "erpnext-backend"

# Check if container is running
$running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null

if ($running -ne $ContainerName) {
    Write-Host "✗ Container $ContainerName is not running" -ForegroundColor Red
    Write-Host "  Start it with: .\start-erpnext.ps1" -ForegroundColor Yellow
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


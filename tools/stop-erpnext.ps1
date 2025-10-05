#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stops ERPNext Docker containers

.DESCRIPTION
    Stops all running ERPNext containers without removing them.

.PARAMETER Remove
    Remove containers, networks, and volumes after stopping

.EXAMPLE
    .\stop-erpnext.ps1
    
.EXAMPLE
    .\stop-erpnext.ps1 -Remove
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DockerComposeFile = Join-Path $ProjectRoot "docker-compose.yml"

Write-Host "Stopping ERPNext containers..." -ForegroundColor Cyan

if ($Remove) {
    docker-compose -f $DockerComposeFile down -v
    Write-Host "✓ Containers stopped and removed (including volumes)" -ForegroundColor Green
} else {
    docker-compose -f $DockerComposeFile stop
    Write-Host "✓ Containers stopped" -ForegroundColor Green
}


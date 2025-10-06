#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Stops ERPNext Docker containers

.DESCRIPTION
    Stops ERPNext containers using frappe_docker/pwd.yml.

.PARAMETER FrappeDockerPath
    Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)

.PARAMETER Remove
    Remove containers, networks, and volumes after stopping

.EXAMPLE
    .\stop-erpnext.ps1
    
.EXAMPLE
    .\stop-erpnext.ps1 -Remove
    
.EXAMPLE
    .\stop-erpnext.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "D:\ErpNext\frappe_docker",
    
    [Parameter(Mandatory=$false)]
    [switch]$Remove
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

Write-Host "Stopping ERPNext containers (using pwd.yml)..." -ForegroundColor Cyan

Push-Location $FrappeDockerPath
try {
    if ($Remove) {
        Write-Host "⚠ WARNING: This will remove ALL data including databases!" -ForegroundColor Red
        $confirm = Read-Host "Are you sure? Type 'yes' to confirm"
        if ($confirm -ne "yes") {
            Write-Host "Cancelled." -ForegroundColor Yellow
            exit 0
        }
        
        docker compose -f pwd.yml down -v
        Write-Host "✓ Containers stopped and removed (including volumes)" -ForegroundColor Green
    } else {
        docker compose -f pwd.yml stop
        Write-Host "✓ Containers stopped" -ForegroundColor Green
    }
} finally {
    Pop-Location
}


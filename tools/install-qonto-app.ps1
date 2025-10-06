#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs or reinstalls Qonto Connector app in ERPNext

.DESCRIPTION
    This script installs the Qonto Connector app into an existing ERPNext site.
    Works with both development and production (pwd.yml) deployments.
    Handles:
    - Installing Python dependencies
    - Installing the app on the site
    - Running migrations
    - Clearing caches

.PARAMETER SiteName
    The ERPNext site name (default: frontend for production, auto-detect for dev)

.PARAMETER FrappeDockerPath
    Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)

.EXAMPLE
    .\install-qonto-app.ps1
    
.EXAMPLE
    .\install-qonto-app.ps1 -SiteName "frontend"
    
.EXAMPLE
    .\install-qonto-app.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "frontend",
    
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "D:\ErpNext\frappe_docker"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$QontoAppPath = Join-Path $ProjectRoot "qonto_connector"

function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Error-Custom { param($Message) Write-Host $Message -ForegroundColor Red }

Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host "   Qonto Connector Installation (Production)" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

Write-Info "Using frappe_docker/pwd.yml configuration"

# Find backend container
$ProjectName = (Split-Path $ProjectRoot -Leaf) -replace '[^a-z0-9]', ''
$PossibleNames = @(
    "${ProjectName}-backend-1",
    "erpnext-qonto-backend-1",
    "erpnext-backend",
    "backend",
    "devcontainer-frappe-1"
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
    Write-Error-Custom "✗ Backend container not running"
    Write-Host "  Available containers:" -ForegroundColor Yellow
    docker ps --format "table {{.Names}}\t{{.Status}}"
    exit 1
}

Write-Success "✓ Container found: $ContainerName"

Write-Success "✓ Site name: $SiteName"

Write-Info "`nStep 1: Copying app to container..."
docker cp $QontoAppPath ${ContainerName}:/home/frappe/frappe-bench/apps/qonto_connector

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "✗ Failed to copy app to container"
    exit 1
}
Write-Success "✓ App copied to container"

Write-Info "`nStep 2: Installing app on site '$SiteName'..."
docker exec $ContainerName bash -c @"
cd /home/frappe/frappe-bench && \
bench --site $SiteName install-app qonto_connector
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠ App may already be installed" -ForegroundColor Yellow
} else {
    Write-Success "✓ App installed on site"
}

Write-Info "`nStep 3: Running migrations..."
docker exec $ContainerName bash -c "bench --site $SiteName migrate" | Out-Null
Write-Success "✓ Migrations completed"

Write-Info "`nStep 4: Clearing cache..."
docker exec $ContainerName bash -c "bench --site $SiteName clear-cache" | Out-Null
Write-Success "✓ Cache cleared"

Write-Info "`nStep 5: Restarting backend..."

# Check if frappe_docker path exists
if (Test-Path $FrappeDockerPath) {
    Push-Location $FrappeDockerPath
    try {
        docker compose -f pwd.yml restart backend | Out-Null
        Start-Sleep -Seconds 5
        Write-Success "✓ Backend restarted"
    } finally {
        Pop-Location
    }
} else {
    Write-Host "⚠ Could not find frappe_docker at: $FrappeDockerPath" -ForegroundColor Yellow
    Write-Host "  Restart backend manually with: docker restart backend" -ForegroundColor Yellow
}

Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host "   Installation Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Access ERPNext at http://localhost:8080" -ForegroundColor White
Write-Host "  2. Go to: Desk > Qonto Connector > Qonto Settings" -ForegroundColor White
Write-Host "  3. Configure your Qonto API credentials" -ForegroundColor White
Write-Host "  4. Test the connection" -ForegroundColor White
Write-Host "  5. Map your bank accounts" -ForegroundColor White
Write-Host ""
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""


#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs Qonto Connector app in ERPNext

.DESCRIPTION
    Installs and configures the Qonto Connector app in the ERPNext site.

.PARAMETER SiteName
    The ERPNext site name (default: erpnext.local)

.EXAMPLE
    .\install-qonto-app.ps1
    
.EXAMPLE
    .\install-qonto-app.ps1 -SiteName "mysite.local"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "erpnext.local"
)

$ErrorActionPreference = "Stop"
$ContainerName = "erpnext-backend"

function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Error-Custom { param($Message) Write-Host $Message -ForegroundColor Red }

Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host "   Qonto Connector Installation" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

# Check if container is running
$running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null

if ($running -ne $ContainerName) {
    Write-Error-Custom "✗ Container $ContainerName is not running"
    Write-Host "  Start it with: .\start-erpnext.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Info "Step 1: Getting app from mounted volume..."
docker exec $ContainerName bash -c "cd /home/frappe/frappe-bench/apps && ls -la qonto_connector"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "✗ Qonto Connector app not found in mounted volume"
    exit 1
}

Write-Success "✓ Qonto Connector app found"

Write-Info "`nStep 2: Installing dependencies..."
docker exec $ContainerName bash -c "pip3 install -r /home/frappe/frappe-bench/apps/qonto_connector/requirements.txt"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "✗ Failed to install dependencies"
    exit 1
}

Write-Success "✓ Dependencies installed"

Write-Info "`nStep 3: Installing app on site '$SiteName'..."
docker exec $ContainerName bash -c "bench --site $SiteName install-app qonto_connector"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "✗ Failed to install app"
    exit 1
}

Write-Success "✓ App installed"

Write-Info "`nStep 4: Running migrations..."
docker exec $ContainerName bash -c "bench --site $SiteName migrate"

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "✗ Migration failed"
    exit 1
}

Write-Success "✓ Migrations completed"

Write-Info "`nStep 5: Clearing cache..."
docker exec $ContainerName bash -c "bench --site $SiteName clear-cache"

Write-Success "✓ Cache cleared"

Write-Info "`nStep 6: Building assets..."
docker exec $ContainerName bash -c "bench build"

Write-Success "✓ Assets built"

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


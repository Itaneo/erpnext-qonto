#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up ERPNext v15 Docker environment using official frappe_docker
.DESCRIPTION
    Configures and starts ERPNext v15 using frappe_docker with support for:
    - Development mode: VSCode devcontainer with local app mounting
    - Production mode: Uses frappe_docker/pwd.yml configuration
.PARAMETER Mode
    Deployment mode: 'development' or 'production' (default: development)
.PARAMETER SiteName
    Site name (default: development.localhost for dev, frontend for prod)
.PARAMETER AdminPassword
    Admin password (default: admin)
.PARAMETER DBPassword
    Database root password (default: admin for pwd.yml compatibility)
.PARAMETER FrappeDockerPath
    Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)
.PARAMETER Pull
    Pull latest images before starting
.PARAMETER Recreate
    Recreate containers
.EXAMPLE
    .\setup-erpnext-docker.ps1
    # Sets up development environment with VSCode devcontainer
.EXAMPLE
    .\setup-erpnext-docker.ps1 -Mode production
    # Sets up production environment using frappe_docker/pwd.yml
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "production")]
    [string]$Mode = "development",
    
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AdminPassword = "admin",
    
    [Parameter(Mandatory=$false)]
    [string]$DBPassword = "admin",
    
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "..\..\frappe_docker",
    
    [Parameter(Mandatory=$false)]
    [switch]$Pull,
    
    [Parameter(Mandatory=$false)]
    [switch]$Recreate
)

$ErrorActionPreference = "Stop"

# Paths
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$QontoAppPath = Join-Path $ProjectRoot "qonto_connector"

# Set default site name based on mode
if (-not $SiteName) {
    $SiteName = if ($Mode -eq "development") { "development.localhost" } else { "frontend" }
}

# Banner
Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host " ERPNext v15 + Qonto Connector Setup ($Mode mode)" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (!(docker info 2>$null)) {
    Write-Host "✗ Docker not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker is running" -ForegroundColor Green

# Check frappe_docker exists
if (!(Test-Path $FrappeDockerPath)) {
    Write-Host "✗ frappe_docker not found at: $FrappeDockerPath" -ForegroundColor Red
    Write-Host "  Clone it with: git clone https://github.com/itaneo/frappe_docker $FrappeDockerPath" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ frappe_docker found" -ForegroundColor Green

# Check Qonto app exists
if (!(Test-Path $QontoAppPath)) {
    Write-Host "✗ Qonto Connector app not found at: $QontoAppPath" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Qonto Connector app found" -ForegroundColor Green

if ($Mode -eq "development") {
    Write-Host "`n--- Setting up DEVELOPMENT environment ---" -ForegroundColor Cyan
    
    # Check if .devcontainer exists
    $DevContainerPath = Join-Path $FrappeDockerPath ".devcontainer"
    if (!(Test-Path $DevContainerPath)) {
        Write-Host "Creating devcontainer configuration..." -ForegroundColor Yellow
        Copy-Item -Path (Join-Path $FrappeDockerPath "devcontainer-example") -Destination $DevContainerPath -Recurse
        Write-Host "✓ Devcontainer created" -ForegroundColor Green
    }
    
    # Create development directory
    $DevelopmentPath = Join-Path $FrappeDockerPath "development"
    if (!(Test-Path $DevelopmentPath)) {
        New-Item -ItemType Directory -Path $DevelopmentPath -Force | Out-Null
        Write-Host "✓ Development directory created" -ForegroundColor Green
    }
    
    # Update docker-compose to mount qonto_connector
    $DevComposeFile = Join-Path $DevContainerPath "docker-compose.yml"
    Write-Host "✓ Use VSCode to open frappe_docker folder" -ForegroundColor Yellow
    Write-Host "  Command: code $FrappeDockerPath" -ForegroundColor White
    Write-Host "  Then: Reopen in Container (Ctrl+Shift+P)" -ForegroundColor White
    Write-Host ""
    Write-Host "After container starts, run inside container:" -ForegroundColor Yellow
    Write-Host "  bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench" -ForegroundColor White
    Write-Host "  cd frappe-bench" -ForegroundColor White
    Write-Host "  bench set-config -g db_host mariadb" -ForegroundColor White
    Write-Host "  bench set-config -g redis_cache redis://redis-cache:6379" -ForegroundColor White
    Write-Host "  bench set-config -g redis_queue redis://redis-queue:6379" -ForegroundColor White
    Write-Host "  bench set-config -g redis_socketio redis://redis-queue:6379" -ForegroundColor White
    Write-Host "  bench new-site --mariadb-user-host-login-scope='%' --admin-password=$AdminPassword --db-root-password=$DBPassword $SiteName" -ForegroundColor White
    Write-Host "  bench get-app erpnext --branch version-15" -ForegroundColor White
    Write-Host "  bench --site $SiteName install-app erpnext" -ForegroundColor White
    Write-Host "  bench get-app https://github.com/itaneo/qonto_connector --branch itaneo" -ForegroundColor White
    Write-Host "  bench --site $SiteName install-app qonto_connector" -ForegroundColor White
    Write-Host "  bench --site $SiteName set-config developer_mode 1" -ForegroundColor White
    Write-Host "  bench start" -ForegroundColor White
    Write-Host ""
    Write-Host "For detailed instructions, see: $FrappeDockerPath\docs\development.md" -ForegroundColor Cyan
    
} else {
    Write-Host "`n--- Setting up PRODUCTION environment ---" -ForegroundColor Cyan
    Write-Host "Using official frappe_docker/pwd.yml configuration" -ForegroundColor Yellow
    
    # Check pwd.yml exists
    $PwdYmlPath = Join-Path $FrappeDockerPath "pwd.yml"
    if (!(Test-Path $PwdYmlPath)) {
        Write-Host "✗ pwd.yml not found at: $PwdYmlPath" -ForegroundColor Red
        Write-Host "  Make sure frappe_docker is up to date" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ Found pwd.yml" -ForegroundColor Green
    
    # Navigate to frappe_docker directory
    Push-Location $FrappeDockerPath
    try {
        if ($Pull) {
            Write-Host "`nPulling latest images..." -ForegroundColor Yellow
            docker compose -f pwd.yml pull
        }
        
        # Start services
        Write-Host "`nStarting services with pwd.yml..." -ForegroundColor Yellow
        if ($Recreate) {
            docker compose -f pwd.yml up -d --force-recreate
        } else {
            docker compose -f pwd.yml up -d
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "✗ Failed to start containers" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "✓ Containers started" -ForegroundColor Green
        
        # Wait for site creation to complete (pwd.yml creates site automatically)
        Write-Host "`nWaiting for automatic site creation..." -ForegroundColor Yellow
        Write-Host "This may take several minutes on first run..." -ForegroundColor Yellow
        
        # Monitor create-site service
        $maxWait = 300  # 5 minutes
        $elapsed = 0
        $siteCreated = $false
        
        while ($elapsed -lt $maxWait) {
            Start-Sleep -Seconds 10
            $elapsed += 10
            
            # Check if create-site container has exited successfully
            $createSiteStatus = docker compose -f pwd.yml ps create-site --format json 2>$null | ConvertFrom-Json
            if ($createSiteStatus.State -eq "exited" -and $createSiteStatus.ExitCode -eq 0) {
                $siteCreated = $true
                break
            }
            
            Write-Host "." -NoNewline
        }
        Write-Host ""
        
        if ($siteCreated) {
            Write-Host "✓ Site created successfully" -ForegroundColor Green
            
            # Install Qonto Connector app
            Write-Host "`nInstalling Qonto Connector app..." -ForegroundColor Yellow
            
            # Check if user wants to install from git or local
            $AppsJsonPath = Join-Path $ProjectRoot "apps.json"
            if (Test-Path $AppsJsonPath) {
                $appsContent = Get-Content $AppsJsonPath -Raw
                try {
                    $appsArray = $appsContent | ConvertFrom-Json
                    $qontoApp = $appsArray | Where-Object { $_.url -match "qonto_connector" } | Select-Object -First 1
                    
                    if ($qontoApp) {
                        $qontoUrl = $qontoApp.url
                        $qontoBranch = if ($qontoApp.branch) { $qontoApp.branch } else { "main" }
                        
                        Write-Host "Installing from git: $qontoUrl" -ForegroundColor Cyan
                        docker compose -f pwd.yml exec backend bash -c "cd /home/frappe/frappe-bench && bench get-app $qontoUrl --branch $qontoBranch && bench --site $SiteName install-app qonto_connector && bench --site $SiteName migrate"
                    }
                } catch {
                    Write-Host "⚠ Could not parse apps.json, will try local install" -ForegroundColor Yellow
                }
            }
            
            # If no git install, try local copy
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Installing from local directory..." -ForegroundColor Cyan
                
                # Copy local qonto_connector to container
                docker cp $QontoAppPath backend:/home/frappe/frappe-bench/apps/qonto_connector
                
                # Install the app
                docker compose -f pwd.yml exec backend bash -c "cd /home/frappe/frappe-bench && bench --site $SiteName install-app qonto_connector && bench --site $SiteName migrate"
            }
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Qonto Connector installed successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠ Failed to install Qonto Connector" -ForegroundColor Yellow
                Write-Host "  You can install it manually later:" -ForegroundColor Yellow
                Write-Host "  cd $FrappeDockerPath" -ForegroundColor White
                Write-Host "  docker compose -f pwd.yml exec backend bash" -ForegroundColor White
                Write-Host "  bench get-app https://github.com/YOUR-USERNAME/qonto_connector" -ForegroundColor White
                Write-Host "  bench --site $SiteName install-app qonto_connector" -ForegroundColor White
            }
            
        } else {
            Write-Host "⚠ Site creation timed out or failed" -ForegroundColor Yellow
            Write-Host "  Check logs: docker compose -f pwd.yml logs create-site" -ForegroundColor Yellow
        }
        
        # Wait for frontend
        Write-Host "`nWaiting for frontend (may take 1-2 minutes)..." -ForegroundColor Yellow
        $ready = $false
        for ($i = 1; $i -le 24; $i++) {
            Start-Sleep -Seconds 5
            try {
                $response = Invoke-WebRequest "http://localhost:8080" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $ready = $true
                    break
                }
            } catch {
                Write-Host "." -NoNewline
            }
        }
        Write-Host ""
        
        if ($ready) {
            Write-Host "✓ Frontend is ready!" -ForegroundColor Green
        } else {
            Write-Host "⚠ Frontend may need more time" -ForegroundColor Yellow
            Write-Host "  Check logs: docker compose -f pwd.yml logs frontend" -ForegroundColor Yellow
        }
        
    } finally {
        Pop-Location
    }
}

# Summary
Write-Host "`n===========================================================" -ForegroundColor Green
Write-Host " ✓ Setup Complete! ($Mode mode)" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""

if ($Mode -eq "development") {
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Open VSCode: code $FrappeDockerPath" -ForegroundColor White
    Write-Host "  2. Reopen in Container (Ctrl+Shift+P)" -ForegroundColor White
    Write-Host "  3. Follow the instructions above to setup bench" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation: $FrappeDockerPath\docs\development.md" -ForegroundColor Cyan
} else {
    Write-Host "Access ERPNext at: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "Login: Administrator / admin" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠ IMPORTANT: Change default password immediately!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manage services with:" -ForegroundColor Yellow
    Write-Host "  cd $FrappeDockerPath" -ForegroundColor White
    Write-Host "  docker compose -f pwd.yml stop" -ForegroundColor White
    Write-Host "  docker compose -f pwd.yml start" -ForegroundColor White
    Write-Host "  docker compose -f pwd.yml logs -f" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use convenience scripts:" -ForegroundColor Yellow
    Write-Host "  .\tools\start-erpnext.ps1 -FrappeDockerPath $FrappeDockerPath" -ForegroundColor White
    Write-Host "  .\tools\stop-erpnext.ps1 -FrappeDockerPath $FrappeDockerPath" -ForegroundColor White
    Write-Host "  .\tools\logs-erpnext.ps1 -FrappeDockerPath $FrappeDockerPath" -ForegroundColor White
}

Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""

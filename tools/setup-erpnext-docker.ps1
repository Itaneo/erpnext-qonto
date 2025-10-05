#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sets up ERPNext v15 Docker container with mounted volumes to D:\ErpNext

.DESCRIPTION
    This script creates the necessary directory structure and Docker Compose
    configuration to run ERPNext v15 with persistent data on D:\ErpNext.
    
    It includes:
    - MariaDB database
    - Redis cache and queue
    - ERPNext frontend and backend
    - Scheduler and workers
    - Socketio for real-time features

.PARAMETER SiteName
    The ERPNext site name (default: erpnext.local)

.PARAMETER AdminPassword
    The Administrator password (default: admin)

.PARAMETER MariaDBRootPassword
    The MariaDB root password (default: erpnext123)

.PARAMETER Pull
    Pull latest Docker images before starting

.PARAMETER Recreate
    Recreate containers even if configuration hasn't changed

.EXAMPLE
    .\setup-erpnext-docker.ps1
    
.EXAMPLE
    .\setup-erpnext-docker.ps1 -SiteName "mysite.local" -AdminPassword "SecurePass123" -Pull

.NOTES
    Author: Itanéo
    Version: 1.0.0
    Requires: Docker Desktop for Windows
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SiteName = "erpnext.local",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$AdminPassword,
    
    [Parameter(Mandatory=$false)]
    [SecureString]$MariaDBRootPassword,
    
    [Parameter(Mandatory=$false)]
    [switch]$Pull,
    
    [Parameter(Mandatory=$false)]
    [switch]$Recreate
)

# Error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Configuration
$BaseDir = "D:\ErpNext"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$DockerComposeFile = Join-Path $ProjectRoot "docker-compose.yml"
$EnvFile = Join-Path $ProjectRoot ".env"

# Convert SecureStrings to plain text for configuration
if (-not $AdminPassword) {
    $AdminPasswordPlain = "admin"
} else {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    $AdminPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

if (-not $MariaDBRootPassword) {
    $MariaDBRootPasswordPlain = "erpnext123"
} else {
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MariaDBRootPassword)
    $MariaDBRootPasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

# Colors for output
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error-Custom { param($Message) Write-Host $Message -ForegroundColor Red }

# Banner
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host "   ERPNext v15 Docker Setup Script" -ForegroundColor Magenta
Write-Host "   Qonto Connector Development Environment" -ForegroundColor Magenta
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""

# Check if Docker is running
Write-Info "Checking Docker status..."
try {
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running"
    }
    Write-Success "✓ Docker is running"
} catch {
    Write-Error-Custom "✗ Docker is not running. Please start Docker Desktop and try again."
    exit 1
}

# Create directory structure
Write-Info "`nCreating directory structure at $BaseDir..."
$directories = @(
    "$BaseDir\sites",
    "$BaseDir\logs",
    "$BaseDir\apps",
    "$BaseDir\mariadb",
    "$BaseDir\redis-cache",
    "$BaseDir\redis-queue",
    "$BaseDir\redis-socketio"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Success "  ✓ Created: $dir"
    } else {
        Write-Info "  ℹ Already exists: $dir"
    }
}

# Create .env file
Write-Info "`nCreating .env file..."
$envContent = @"
# ERPNext Configuration
ERPNEXT_VERSION=v15
FRAPPE_VERSION=version-15
SITE_NAME=$SiteName
ADMIN_PASSWORD=$AdminPasswordPlain

# Database Configuration
DB_ROOT_PASSWORD=$MariaDBRootPasswordPlain
DB_HOST=mariadb
DB_PORT=3306

# Redis Configuration
REDIS_CACHE_HOST=redis-cache
REDIS_QUEUE_HOST=redis-queue
REDIS_SOCKETIO_HOST=redis-socketio

# Volume Paths
SITES_DIR=$BaseDir\sites
LOGS_DIR=$BaseDir\logs
APPS_DIR=$BaseDir\apps
MARIADB_DIR=$BaseDir\mariadb

# Network Configuration
BACKEND_PORT=8000
FRONTEND_PORT=8080
SOCKETIO_PORT=9000
"@

Set-Content -Path $EnvFile -Value $envContent -Force
Write-Success "✓ .env file created"

# Create docker-compose.yml
Write-Info "`nCreating docker-compose.yml..."
$dockerComposeContent = @"
version: "3.8"

services:
  # MariaDB Database
  mariadb:
    image: mariadb:10.6
    container_name: erpnext-mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: `${DB_ROOT_PASSWORD}
    volumes:
      - mariadb-data:/var/lib/mysql
      - type: bind
        source: `${MARIADB_DIR}
        target: /var/lib/mysql/backup
    networks:
      - erpnext-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p`${DB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis-cache:
    image: redis:7-alpine
    container_name: erpnext-redis-cache
    restart: unless-stopped
    volumes:
      - redis-cache-data:/data
    networks:
      - erpnext-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Queue
  redis-queue:
    image: redis:7-alpine
    container_name: erpnext-redis-queue
    restart: unless-stopped
    volumes:
      - redis-queue-data:/data
    networks:
      - erpnext-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Socketio
  redis-socketio:
    image: redis:7-alpine
    container_name: erpnext-redis-socketio
    restart: unless-stopped
    volumes:
      - redis-socketio-data:/data
    networks:
      - erpnext-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ERPNext Backend
  backend:
    image: frappe/erpnext:v15
    container_name: erpnext-backend
    restart: unless-stopped
    depends_on:
      mariadb:
        condition: service_healthy
      redis-cache:
        condition: service_healthy
      redis-queue:
        condition: service_healthy
    environment:
      DB_HOST: `${DB_HOST}
      DB_PORT: `${DB_PORT}
      REDIS_CACHE: `${REDIS_CACHE_HOST}:6379
      REDIS_QUEUE: `${REDIS_QUEUE_HOST}:6379
      REDIS_SOCKETIO: `${REDIS_SOCKETIO_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
      - type: bind
        source: `${LOGS_DIR}
        target: /home/frappe/frappe-bench/logs
      - type: bind
        source: $ProjectRoot\qonto_connector
        target: /home/frappe/frappe-bench/apps/qonto_connector
    networks:
      - erpnext-network
    ports:
      - "`${BACKEND_PORT}:8000"
    command: >
      bash -c "
        if [ ! -d sites/`${SITE_NAME} ]; then
          echo 'Creating new site: `${SITE_NAME}';
          bench new-site `${SITE_NAME}
            --db-root-password `${DB_ROOT_PASSWORD}
            --admin-password `${ADMIN_PASSWORD}
            --no-mariadb-socket;
          bench --site `${SITE_NAME} install-app erpnext;
          bench --site `${SITE_NAME} set-config developer_mode 1;
          bench --site `${SITE_NAME} clear-cache;
        fi;
        bench start
      "

  # ERPNext Frontend (Nginx)
  frontend:
    image: frappe/erpnext:v15
    container_name: erpnext-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      BACKEND: backend:8000
      SOCKETIO: socketio:9000
      SITE_NAME: `${SITE_NAME}
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
    networks:
      - erpnext-network
    ports:
      - "`${FRONTEND_PORT}:8080"

  # Socketio for real-time features
  socketio:
    image: frappe/erpnext:v15
    container_name: erpnext-socketio
    restart: unless-stopped
    depends_on:
      - redis-socketio
    environment:
      REDIS_SOCKETIO: `${REDIS_SOCKETIO_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
    networks:
      - erpnext-network
    ports:
      - "`${SOCKETIO_PORT}:9000"
    command: ["node", "/home/frappe/frappe-bench/apps/frappe/socketio.js"]

  # Queue Workers
  queue-default:
    image: frappe/erpnext:v15
    container_name: erpnext-queue-default
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      DB_HOST: `${DB_HOST}
      REDIS_CACHE: `${REDIS_CACHE_HOST}:6379
      REDIS_QUEUE: `${REDIS_QUEUE_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
      - type: bind
        source: $ProjectRoot\qonto_connector
        target: /home/frappe/frappe-bench/apps/qonto_connector
    networks:
      - erpnext-network
    command: ["bench", "worker", "--queue", "default"]

  queue-short:
    image: frappe/erpnext:v15
    container_name: erpnext-queue-short
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      DB_HOST: `${DB_HOST}
      REDIS_CACHE: `${REDIS_CACHE_HOST}:6379
      REDIS_QUEUE: `${REDIS_QUEUE_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
      - type: bind
        source: $ProjectRoot\qonto_connector
        target: /home/frappe/frappe-bench/apps/qonto_connector
    networks:
      - erpnext-network
    command: ["bench", "worker", "--queue", "short"]

  queue-long:
    image: frappe/erpnext:v15
    container_name: erpnext-queue-long
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      DB_HOST: `${DB_HOST}
      REDIS_CACHE: `${REDIS_CACHE_HOST}:6379
      REDIS_QUEUE: `${REDIS_QUEUE_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
      - type: bind
        source: $ProjectRoot\qonto_connector
        target: /home/frappe/frappe-bench/apps/qonto_connector
    networks:
      - erpnext-network
    command: ["bench", "worker", "--queue", "long"]

  # Scheduler
  scheduler:
    image: frappe/erpnext:v15
    container_name: erpnext-scheduler
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      DB_HOST: `${DB_HOST}
      REDIS_CACHE: `${REDIS_CACHE_HOST}:6379
      REDIS_QUEUE: `${REDIS_QUEUE_HOST}:6379
    volumes:
      - type: bind
        source: `${SITES_DIR}
        target: /home/frappe/frappe-bench/sites
      - type: bind
        source: $ProjectRoot\qonto_connector
        target: /home/frappe/frappe-bench/apps/qonto_connector
    networks:
      - erpnext-network
    command: ["bench", "schedule"]

networks:
  erpnext-network:
    driver: bridge

volumes:
  mariadb-data:
  redis-cache-data:
  redis-queue-data:
  redis-socketio-data:
"@

Set-Content -Path $DockerComposeFile -Value $dockerComposeContent -Force
Write-Success "✓ docker-compose.yml created"

# Pull images if requested
if ($Pull) {
    Write-Info "`nPulling Docker images..."
    docker-compose -f $DockerComposeFile pull
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Images pulled successfully"
    } else {
        Write-Warning "⚠ Some images may not have been pulled"
    }
}

# Start containers
Write-Info "`nStarting ERPNext containers..."
$composeArgs = @("-f", $DockerComposeFile, "up", "-d")
if ($Recreate) {
    $composeArgs += "--force-recreate"
}

docker-compose @composeArgs

if ($LASTEXITCODE -eq 0) {
    Write-Success "`n✓ ERPNext containers started successfully!"
} else {
    Write-Error-Custom "`n✗ Failed to start containers"
    exit 1
}

# Wait for services to be ready
Write-Info "`nWaiting for services to be ready (this may take a few minutes)..."
$maxAttempts = 60
$attempt = 0
$ready = $false

while ($attempt -lt $maxAttempts -and -not $ready) {
    $attempt++
    Start-Sleep -Seconds 5
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$($env:FRONTEND_PORT = '8080')" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            $ready = $true
        }
    } catch {
        Write-Host "." -NoNewline
    }
}

Write-Host ""

if ($ready) {
    Write-Success "✓ ERPNext is ready!"
} else {
    Write-Warning "⚠ ERPNext is starting but may need more time. Check with 'docker-compose logs -f backend'"
}

# Summary
Write-Host "`n==================================================" -ForegroundColor Magenta
Write-Host "   Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend:  http://localhost:8080" -ForegroundColor White
Write-Host "  Backend:   http://localhost:8000" -ForegroundColor White
Write-Host ""
Write-Host "Credentials:" -ForegroundColor Cyan
Write-Host "  Site:      $SiteName" -ForegroundColor White
Write-Host "  Username:  Administrator" -ForegroundColor White
Write-Host "  Password:  $AdminPasswordPlain" -ForegroundColor White
Write-Host ""
Write-Host "Data Location:" -ForegroundColor Cyan
Write-Host "  $BaseDir" -ForegroundColor White
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Cyan
Write-Host "  View logs:     docker-compose logs -f" -ForegroundColor White
Write-Host "  Stop:          docker-compose down" -ForegroundColor White
Write-Host "  Restart:       docker-compose restart" -ForegroundColor White
Write-Host "  Shell access:  docker exec -it erpnext-backend bash" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Access ERPNext at http://localhost:8080" -ForegroundColor White
Write-Host "  2. Log in with Administrator/$AdminPasswordPlain" -ForegroundColor White
Write-Host "  3. Install the Qonto Connector app" -ForegroundColor White
Write-Host "  4. Configure Qonto Settings" -ForegroundColor White
Write-Host ""
Write-Host "==================================================" -ForegroundColor Magenta
Write-Host ""


#!/usr/bin/env pwsh
<#
.SYNOPSIS
    [DEPRECATED] This script is no longer recommended. Use official images instead.

.DESCRIPTION
    This project now uses official frappe/erpnext images without building custom images.
    The Qonto Connector app is installed at runtime instead.
    
    This script is kept for reference purposes only.
    
    For the new approach, use:
        .\tools\setup-erpnext-docker.ps1 -Mode production
    
    The new approach:
    - Uses official frappe/erpnext Docker images
    - Installs qonto_connector at runtime (from git or local mount)
    - Faster deployment (no image building required)
    - Easier updates and maintenance

.PARAMETER FrappeDockerPath
    Path to frappe_docker repository (default: D:\ErpNext\frappe_docker)

.PARAMETER ImageTag
    Docker image tag (default: erpnext-qonto:latest)

.PARAMETER FrappeVersion
    Frappe/ERPNext version branch (default: version-15)

.PARAMETER UseCache
    Use Docker build cache (default: true)

.EXAMPLE
    # INSTEAD OF THIS SCRIPT, USE:
    .\setup-erpnext-docker.ps1 -Mode production
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$FrappeDockerPath = "D:\ErpNext\frappe_docker",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "erpnext-qonto:latest",
    
    [Parameter(Mandatory=$false)]
    [string]$FrappeVersion = "version-15",
    
    [Parameter(Mandatory=$false)]
    [bool]$UseCache = $true
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Deprecation Banner
Write-Host "`n===========================================================" -ForegroundColor Red
Write-Host " ⚠ DEPRECATED: Custom Image Building No Longer Recommended" -ForegroundColor Red
Write-Host "===========================================================" -ForegroundColor Red
Write-Host ""
Write-Host "This project now uses official frappe/erpnext Docker images." -ForegroundColor Yellow
Write-Host "The Qonto Connector app is installed at runtime instead." -ForegroundColor Yellow
Write-Host ""
Write-Host "✓ Benefits of new approach:" -ForegroundColor Green
Write-Host "  - No image building required (saves 10-20 minutes)" -ForegroundColor White
Write-Host "  - Use official, tested images from Frappe" -ForegroundColor White
Write-Host "  - Easier updates and maintenance" -ForegroundColor White
Write-Host "  - Better security (official images only)" -ForegroundColor White
Write-Host ""
Write-Host "📖 Use this instead:" -ForegroundColor Cyan
Write-Host "  .\tools\setup-erpnext-docker.ps1 -Mode production" -ForegroundColor White
Write-Host ""
$continue = Read-Host "Continue with custom image build anyway? (y/N)"
if ($continue -ne "y") {
    Write-Host "Exiting. Please use the recommended setup script." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host " Building Custom ERPNext Image with Qonto Connector" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

# Check Docker
if (!(docker info 2>$null)) {
    Write-Host "✗ Docker not running. Start Docker Desktop first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker is running" -ForegroundColor Green

# Check frappe_docker
if (!(Test-Path $FrappeDockerPath)) {
    Write-Host "✗ frappe_docker not found at: $FrappeDockerPath" -ForegroundColor Red
    Write-Host "  Clone it with:" -ForegroundColor Yellow
    Write-Host "  git clone https://github.com/frappe/frappe_docker $FrappeDockerPath" -ForegroundColor White
    exit 1
}
Write-Host "✓ frappe_docker found" -ForegroundColor Green

# Check apps.json
$AppsJsonPath = Join-Path $ProjectRoot "apps.json"
if (!(Test-Path $AppsJsonPath)) {
    Write-Host "✗ apps.json not found at: $AppsJsonPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Create apps.json with your git repository URLs:" -ForegroundColor Yellow
    Write-Host "  1. For public repos, use: apps-example.json as template" -ForegroundColor White
    Write-Host "  2. For private repos, use: apps-private-example.json as template" -ForegroundColor White
    Write-Host ""
    Write-Host "  Example apps.json:" -ForegroundColor Cyan
    Write-Host '  [' -ForegroundColor White
    Write-Host '    {' -ForegroundColor White
    Write-Host '      "url": "https://github.com/frappe/erpnext",' -ForegroundColor White
    Write-Host '      "branch": "version-15"' -ForegroundColor White
    Write-Host '    },' -ForegroundColor White
    Write-Host '    {' -ForegroundColor White
    Write-Host '      "url": "https://github.com/frappe/payments",' -ForegroundColor White
    Write-Host '      "branch": "version-15"' -ForegroundColor White
    Write-Host '    },' -ForegroundColor White
    Write-Host '    {' -ForegroundColor White
    Write-Host '      "url": "https://github.com/YOUR-USERNAME/qonto_connector",' -ForegroundColor White
    Write-Host '      "branch": "main"' -ForegroundColor White
    Write-Host '    }' -ForegroundColor White
    Write-Host '  ]' -ForegroundColor White
    Write-Host ""
    Write-Host "  For private repos, include PAT:" -ForegroundColor Cyan
    Write-Host '  "url": "https://{{PAT}}@github.com/YOUR-ORG/qonto_connector.git"' -ForegroundColor White
    Write-Host ""
    Write-Host "  See: https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md" -ForegroundColor Cyan
    exit 1
}
Write-Host "✓ apps.json found" -ForegroundColor Green

# Validate apps.json
Write-Host "Validating apps.json..." -ForegroundColor Yellow
$appsContent = Get-Content $AppsJsonPath -Raw
try {
    $appsArray = $appsContent | ConvertFrom-Json
    
    # Check each app URL
    $invalidUrls = @()
    foreach ($app in $appsArray) {
        if ($app.url -notmatch '^https?://') {
            $invalidUrls += $app.url
        }
    }
    
    if ($invalidUrls.Count -gt 0) {
        Write-Host "✗ Invalid URLs found in apps.json:" -ForegroundColor Red
        foreach ($url in $invalidUrls) {
            Write-Host "  - $url" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "  All URLs must be http(s) git URLs, not local paths!" -ForegroundColor Yellow
        Write-Host "  Example: https://github.com/YOUR-USERNAME/qonto_connector" -ForegroundColor White
        exit 1
    }
    
    $hasQonto = $appsArray | Where-Object { $_.url -match "qonto_connector" }
    if (-not $hasQonto) {
        Write-Host "⚠ Warning: apps.json doesn't include qonto_connector" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y") {
            exit 0
        }
    }
    
} catch {
    Write-Host "✗ Invalid JSON in apps.json: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "✓ apps.json is valid" -ForegroundColor Green

# Display build configuration
Write-Host ""
Write-Host "Build Configuration:" -ForegroundColor Cyan
Write-Host "  frappe_docker path: $FrappeDockerPath" -ForegroundColor White
Write-Host "  Image tag: $ImageTag" -ForegroundColor White
Write-Host "  Frappe version: $FrappeVersion" -ForegroundColor White
Write-Host "  Use cache: $UseCache" -ForegroundColor White
Write-Host "  Apps to install:" -ForegroundColor White
foreach ($app in $appsArray) {
    Write-Host "    - $($app.url) [$($app.branch)]" -ForegroundColor Gray
}
Write-Host ""

# Confirm
$confirm = Read-Host "Proceed with build? (Y/n)"
if ($confirm -eq "n") {
    Write-Host "Build cancelled." -ForegroundColor Yellow
    exit 0
}

# Generate base64 encoded apps.json
Write-Host "`nGenerating APPS_JSON_BASE64..." -ForegroundColor Yellow
$AppsJsonBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($appsContent))
Write-Host "✓ Base64 encoded" -ForegroundColor Green

# Verify base64 encoding (optional sanity check)
$decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($AppsJsonBase64))
Write-Host "`nDecoded apps.json (verification):" -ForegroundColor Gray
Write-Host $decoded -ForegroundColor Gray
Write-Host ""

# Build image following official frappe_docker process
Write-Host "Building Docker image..." -ForegroundColor Yellow
Write-Host "This may take 10-20 minutes depending on your internet connection..." -ForegroundColor Yellow
Write-Host "Docker will clone all apps from their git repositories." -ForegroundColor Cyan
Write-Host ""

Push-Location $FrappeDockerPath
try {
    $buildArgs = @(
        "build",
        "--build-arg=FRAPPE_PATH=https://github.com/frappe/frappe",
        "--build-arg=FRAPPE_BRANCH=$FrappeVersion",
        "--build-arg=APPS_JSON_BASE64=$AppsJsonBase64",
        "--tag=$ImageTag",
        "--file=images/layered/Containerfile"
    )
    
    if (-not $UseCache) {
        $buildArgs += "--no-cache"
    }
    
    $buildArgs += "."
    
    Write-Host "Running: docker $($buildArgs -join ' ')" -ForegroundColor Gray
    Write-Host ""
    
    & docker @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "✗ Failed to build custom image" -ForegroundColor Red
        Write-Host ""
        Write-Host "Common issues:" -ForegroundColor Yellow
        Write-Host "  1. Git repository not accessible (check URLs and PAT)" -ForegroundColor White
        Write-Host "  2. Branch doesn't exist" -ForegroundColor White
        Write-Host "  3. Network connectivity issues" -ForegroundColor White
        Write-Host "  4. Docker build context issues" -ForegroundColor White
        Write-Host ""
        exit 1
    }
    
} finally {
    Pop-Location
}

# Success
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host " ✓ Image Built Successfully!" -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Image: $ImageTag" -ForegroundColor Cyan
Write-Host ""

# Verify image
$imageInfo = docker images $ImageTag --format "{{.Size}}"
if ($imageInfo) {
    Write-Host "Image size: $imageInfo" -ForegroundColor White
}

# Next steps
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Configure .env file (copy from .env.example)" -ForegroundColor White
Write-Host "  2. Run: .\tools\setup-erpnext-docker.ps1 -Mode production" -ForegroundColor White
Write-Host "  3. Or start manually: docker compose up -d" -ForegroundColor White
Write-Host ""
Write-Host "To push to registry:" -ForegroundColor Cyan
Write-Host "  docker login" -ForegroundColor White
Write-Host "  docker tag $ImageTag your-registry/$ImageTag" -ForegroundColor White
Write-Host "  docker push your-registry/$ImageTag" -ForegroundColor White
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
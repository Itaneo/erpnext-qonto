# Qonto Connector - Installation Guide

This guide provides step-by-step instructions for installing the Qonto Connector app, following the [official Frappe Docker custom apps process](https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Publishing Your App](#publishing-your-app)
- [Production Installation](#production-installation)
- [Development Installation](#development-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before installing, ensure you have:

1. **Docker Desktop** installed and running
2. **Frappe Docker** cloned locally:
   ```bash
   git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker
   ```
3. **Git repository** for qonto_connector (public or private on GitHub/GitLab)
4. **Personal Access Token (PAT)** if using private repositories
   - GitHub: https://github.com/settings/tokens
   - GitLab: https://gitlab.com/-/profile/personal_access_tokens

## Publishing Your App

### Option 1: Public Repository (Recommended for Open Source)

1. Create a new repository on GitHub:
   ```
   https://github.com/YOUR-USERNAME/qonto_connector
   ```

2. Push your qonto_connector code:
   ```bash
   cd D:\ErpNext\erpnext-qonto
   git remote add origin https://github.com/YOUR-USERNAME/qonto_connector.git
   git push -u origin main
   ```

### Option 2: Private Repository

1. Create a private repository on GitHub/GitLab

2. Generate a Personal Access Token (PAT) with `repo` scope

3. You'll use the format: `https://{{PAT}}@github.com/YOUR-ORG/qonto_connector.git`

## Production Installation

Production installations use the **official frappe_docker `pwd.yml`** configuration.

### Step 1: Clone frappe_docker

```bash
# Clone the official frappe_docker repository
git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker
cd D:\ErpNext\frappe_docker
```

### Step 2: Start Services with pwd.yml

```bash
# Start all services (includes site creation automatically)
docker compose -f pwd.yml up -d

# Monitor site creation progress
docker compose -f pwd.yml logs -f create-site
```

Wait until you see: **"Site frontend has been created successfully"**

### Step 3: Install Qonto Connector

#### Option A: From Public Git Repository

```bash
# Enter backend container
docker compose -f pwd.yml exec backend bash

# Install the app
cd /home/frappe/frappe-bench
bench get-app https://github.com/YOUR-USERNAME/qonto_connector
bench --site frontend install-app qonto_connector
bench --site frontend migrate
bench --site frontend clear-cache

# Exit container
exit
```

#### Option B: From Private Git Repository

```bash
# Enter backend container
docker compose -f pwd.yml exec backend bash

# Install with Personal Access Token (PAT)
cd /home/frappe/frappe-bench
bench get-app https://{{YOUR_PAT}}@github.com/YOUR-ORG/qonto_connector.git
bench --site frontend install-app qonto_connector
bench --site frontend migrate
bench --site frontend clear-cache

# Exit container
exit
```

**Getting a PAT:**
- GitHub: https://github.com/settings/tokens
- Required scope: `repo`

#### Option C: From Local Directory (Development/Testing)

```bash
# Copy local app to container
docker cp D:\ErpNext\erpnext-qonto backend:/home/frappe/frappe-bench/apps/qonto_connector

# Enter container and install
docker compose -f pwd.yml exec backend bash
cd /home/frappe/frappe-bench
bench --site frontend install-app qonto_connector
bench --site frontend migrate

# Exit
exit
```

### Step 4: Access ERPNext

Once installation completes:

1. Open browser: `http://localhost:8080`
2. Login with default credentials:
   - Username: `Administrator`
   - Password: `admin` (change this immediately!)

3. Navigate to: **Desk → Qonto Connector → Qonto Settings**

### Step 5: Secure Your Installation

**Important**: Change default passwords immediately!

```bash
# Enter backend container
docker compose -f pwd.yml exec backend bash

# Change admin password
bench --site frontend set-admin-password NEW_SECURE_PASSWORD

# Exit
exit
```

## Development Installation

For development with live code editing:

### Step 1: Use VSCode DevContainer

```powershell
# Open frappe_docker in VSCode
code D:\ErpNext\frappe_docker

# Reopen in Container (Ctrl+Shift+P → "Reopen in Container")
```

### Step 2: Initialize Bench Inside Container

```bash
# Inside the devcontainer terminal
bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench
cd frappe-bench

# Configure connections
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379

# Create site
bench new-site development.localhost \
  --mariadb-user-host-login-scope='%' \
  --admin-password=admin \
  --db-root-password=123

# Get apps
bench get-app erpnext --branch version-15
bench --site development.localhost install-app erpnext

# Get qonto_connector from git
bench get-app https://github.com/YOUR-USERNAME/qonto_connector --branch main
bench --site development.localhost install-app qonto_connector

# Enable developer mode
bench --site development.localhost set-config developer_mode 1

# Start
bench start
```

Access at: `http://development.localhost:8000`

## Verification

### Check App Installation

```bash
# List installed apps
bench --site your-site-name list-apps

# Expected output:
# frappe
# erpnext
# payments
# qonto_connector
```

### Check Docker Image

```powershell
# List images
docker images | Select-String "erpnext-qonto"

# Expected output:
# erpnext-qonto   latest   xxxxxxxxxxxx   X hours ago   XXX MB
```

### Check Services

```powershell
# Check running containers
docker ps

# Expected services:
# - backend
# - frontend
# - websocket
# - queue-short
# - queue-long
# - scheduler
# - mariadb
# - redis-cache
# - redis-queue
```

### Test Qonto Connection

1. Go to: **Desk → Qonto Connector → Qonto Settings**
2. Enter your Qonto API credentials
3. Click **"Test Connection"**
4. Should see: ✓ Connection successful!

## Troubleshooting

### Build Fails: "Could not clone app"

**Problem:** Docker can't access your git repository

**Solutions:**
- For public repos: Ensure URL is correct and accessible
- For private repos: Verify PAT is valid and has `repo` scope
- Test git clone manually: `git clone https://{{PAT}}@github.com/org/repo.git`

### Build Fails: "Invalid apps.json"

**Problem:** JSON syntax error or invalid format

**Solutions:**
```bash
# Validate JSON
cat apps.json | jq empty

# Check for common issues:
# - Missing commas
# - Extra trailing commas
# - Incorrect quotes
# - Local file paths instead of git URLs
```

### Image Built but App Not Found

**Problem:** App wasn't properly installed in the image

**Solutions:**
```bash
# Inspect the image
docker run -it --entrypoint bash erpnext-qonto:latest
ls -la apps/
# Should see: frappe, erpnext, payments, qonto_connector

# Rebuild without cache
.\tools\build-prod-image.ps1 -UseCache:$false
```

### "Apps.json uses local paths"

**Problem:** apps.json contains local file paths instead of git URLs

**Solution:**
```json
# ❌ WRONG - Local path
{
  "url": "./qonto_connector",
  "branch": "main"
}

# ✅ CORRECT - Git URL
{
  "url": "https://github.com/YOUR-USERNAME/qonto_connector",
  "branch": "main"
}
```

### Permission Denied on Git Clone

**Problem:** PAT missing or incorrect permissions

**Solutions:**
1. Verify PAT at: https://github.com/settings/tokens
2. Ensure `repo` scope is enabled
3. Test PAT:
   ```bash
   git ls-remote https://{{PAT}}@github.com/your-org/repo.git
   ```

### Container Starts but App Not Installed

**Problem:** App in image but not installed on site

**Solution:**
```bash
# Install manually
docker exec -it backend bash
cd /home/frappe/frappe-bench
bench --site your-site-name install-app qonto_connector
bench --site your-site-name migrate
bench --site your-site-name clear-cache
```

## Additional Resources

- [Official Frappe Docker Docs](https://github.com/frappe/frappe_docker)
- [Custom Apps Documentation](https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md)
- [Frappe Framework Docs](https://frappeframework.com/docs)
- [ERPNext Documentation](https://docs.erpnext.com/)

## Getting Help

If you encounter issues:

1. Check the logs:
   ```powershell
   .\tools\logs-erpnext.ps1
   # Or specific service:
   docker compose logs backend
   ```

2. Open an issue on GitHub with:
   - Error messages (with sensitive data removed)
   - Steps to reproduce
   - Docker version: `docker --version`
   - OS information

3. Join the Frappe/ERPNext community:
   - Forum: https://discuss.frappe.io/
   - Telegram: https://t.me/frappecommunity



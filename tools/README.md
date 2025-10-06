# ERPNext Docker Tools

PowerShell scripts for managing ERPNext v15 with Docker using **official frappe_docker**.

## 📋 Prerequisites

- Windows 10/11 with PowerShell 7+
- Docker Desktop for Windows installed and running
- At least 8GB RAM available for Docker
- 20GB free disk space
- Git installed
- **frappe_docker** repository cloned: `git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker`

## 🏗️ Deployment Modes

This setup supports two deployment modes:

### **Development Mode** 🛠️
- Uses VSCode devcontainer for local development
- Live code reloading
- Full debugging support
- Apps mounted as volumes from local filesystem
- Best for: Active development, testing, debugging

### **Production Mode** 🚀
- Uses official frappe_docker **pwd.yml** configuration
- Production-tested by Frappe community
- Official images only (no custom builds)
- Best for: Staging, production, demos

## 🚀 Quick Start

### Development Mode Setup

For active development with live code reloading:

```powershell
# 1. Setup development environment
.\tools\setup-erpnext-docker.ps1 -Mode development

# 2. Open frappe_docker in VSCode
code D:\ErpNext\frappe_docker

# 3. In VSCode: Reopen in Container (Ctrl+Shift+P)

# 4. Inside container terminal, run:
bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench
cd frappe-bench
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379
bench new-site --mariadb-user-host-login-scope='%' --admin-password=admin --db-root-password=123 development.localhost
bench get-app erpnext --branch version-15
bench --site development.localhost install-app erpnext
bench get-app D:/ErpNext/erpnext-qonto/qonto_connector
bench --site development.localhost install-app qonto_connector
bench --site development.localhost set-config developer_mode 1
bench start
```

Access: http://development.localhost:8000

### Production Mode Setup

For production deployments using frappe_docker/pwd.yml:

```powershell
# 1. Setup production environment (uses pwd.yml)
.\tools\setup-erpnext-docker.ps1 -Mode production

# 2. Wait for setup to complete
# Services will start using official pwd.yml configuration

# 3. Access ERPNext
# http://localhost:8080
```

Default credentials (from pwd.yml):
- Username: `Administrator`
- Password: `admin` (⚠ change immediately!)
- Site name: `frontend`

## 📦 Available Scripts

### Setup & Installation

#### `setup-erpnext-docker.ps1`
Initial setup for development or production environments.

```powershell
# Development setup
.\tools\setup-erpnext-docker.ps1 -Mode development

# Production setup (uses frappe_docker/pwd.yml)
.\tools\setup-erpnext-docker.ps1 -Mode production

# Production with custom frappe_docker path
.\tools\setup-erpnext-docker.ps1 -Mode production -FrappeDockerPath "D:\Custom\frappe_docker"
```

**Parameters:**
- `-Mode` - Deployment mode: `development` or `production` (default: development)
- `-SiteName` - Site name (default: development.localhost for dev, frontend for prod)
- `-AdminPassword` - Admin password (default: admin) - pwd.yml uses "admin"
- `-DBPassword` - Database root password (default: admin for pwd.yml compatibility)
- `-FrappeDockerPath` - Path to frappe_docker repo (default: D:\ErpNext\frappe_docker)
- `-Pull` - Pull latest images before starting
- `-Recreate` - Recreate containers

**Production Mode:**
- Uses official `frappe_docker/pwd.yml`
- No custom image building required
- Leverages community-tested configuration

#### `install-qonto-app.ps1`
Install or reinstall Qonto Connector on an existing site.

```powershell
# Install on default site (frontend)
.\tools\install-qonto-app.ps1

# Specify site name
.\tools\install-qonto-app.ps1 -SiteName "frontend"

# Custom frappe_docker path
.\tools\install-qonto-app.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
```

**Parameters:**
- `-SiteName` - Target site (default: frontend)
- `-FrappeDockerPath` - Path to frappe_docker (default: D:\ErpNext\frappe_docker)

**Use cases:**
- Reinstalling after app code changes
- Installing on existing sites
- Troubleshooting installation issues

#### `build-prod-image.ps1` ⚠️ DEPRECATED

**This script is deprecated.** The project now uses official `frappe_docker/pwd.yml` for production.

Benefits of using pwd.yml:
- Production-tested configuration
- No custom image building required
- Community-maintained
- Official images only
- Faster deployment

Use `setup-erpnext-docker.ps1 -Mode production` instead.

### Container Management

#### `start-erpnext.ps1`
Start ERPNext containers using frappe_docker/pwd.yml.

```powershell
# Start with default path
.\tools\start-erpnext.ps1

# Custom frappe_docker path
.\tools\start-erpnext.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
```

**Parameters:**
- `-FrappeDockerPath` - Path to frappe_docker (default: D:\ErpNext\frappe_docker)

#### `stop-erpnext.ps1`
Stop ERPNext containers using frappe_docker/pwd.yml.

```powershell
# Stop containers (preserves data)
.\tools\stop-erpnext.ps1

# Stop and remove everything (including volumes)
.\tools\stop-erpnext.ps1 -Remove

# Custom frappe_docker path
.\tools\stop-erpnext.ps1 -FrappeDockerPath "D:\Custom\frappe_docker"
```

**Parameters:**
- `-FrappeDockerPath` - Path to frappe_docker (default: D:\ErpNext\frappe_docker)
- `-Remove` - Remove containers and volumes (requires confirmation)

**⚠️ Warning:** Using `-Remove` will delete all data including databases!

#### `logs-erpnext.ps1`
View container logs using frappe_docker/pwd.yml.

```powershell
# View all service logs (last 100 lines)
.\tools\logs-erpnext.ps1

# Follow specific service logs
.\tools\logs-erpnext.ps1 -Service backend -Follow

# Show more lines with custom path
.\tools\logs-erpnext.ps1 -Lines 500 -FrappeDockerPath "D:\Custom\frappe_docker"
```

**Parameters:**
- `-FrappeDockerPath` - Path to frappe_docker (default: D:\ErpNext\frappe_docker)
- `-Service` - Specific service name (backend, frontend, db, etc.)
- `-Follow` - Follow log output (like tail -f)
- `-Lines` - Number of lines to show (default: 100)

**Common services:**
- `backend` - ERPNext application
- `frontend` - Nginx web server
- `db` / `mariadb` - Database
- `redis-cache`, `redis-queue` - Redis instances
- `queue-short`, `queue-long` - Queue workers
- `scheduler` - Scheduled tasks
- `websocket` - Real-time features
- `configurator` - Configuration service (runs once)

#### `shell-erpnext.ps1`
Open shell in backend container or execute commands.

```powershell
# Interactive bash shell
.\tools\shell-erpnext.ps1

# Execute specific command
.\tools\shell-erpnext.ps1 -Command "bench --version"
.\tools\shell-erpnext.ps1 -Command "bench --site development.localhost migrate"
```

**Parameters:**
- `-Command` - Command to execute (optional, omit for interactive shell)

## 📁 Directory Structure

### Development Mode
```
D:\ErpNext\
├── frappe_docker\              # Official frappe_docker repo
│   ├── .devcontainer\          # VSCode devcontainer config
│   ├── development\            # Your bench directories
│   │   └── frappe-bench\       # Active development bench
│   │       ├── apps\           # Frappe apps
│   │       └── sites\          # Site data
│   └── docs\                   # Documentation
└── erpnext-qonto\              # This project
    ├── qonto_connector\        # App source (mounted in container)
    └── tools\                  # Management scripts
```

### Production Mode (pwd.yml)
```
D:\ErpNext\
├── frappe_docker\              # Official frappe_docker repo
│   ├── pwd.yml                 # Production compose file (used)
│   └── ...                     # Other frappe_docker files
├── erpnext-qonto\              # This project
│   ├── qonto_connector\        # App source (copied to containers)
│   ├── tools\                  # Management scripts
│   └── apps.json               # Optional: Apps manifest for git install
└── Docker volumes (managed by pwd.yml):
    ├── sites\                  # Site data
    ├── db-data\                # Database
    └── redis-*-data\           # Redis data
```

## 🌐 Access Points

### Development Mode
- **Frontend:** http://development.localhost:8000
- **Backend API:** http://localhost:8000
- **Frappe Desk:** http://development.localhost:8000/desk

### Production Mode
- **Frontend:** http://localhost:8080
- **Backend API:** Proxied through frontend
- **Frappe Desk:** http://localhost:8080/desk

**Default Credentials:**
- Username: `Administrator`
- Password: `admin` (or custom if specified)

## 🔍 Common Operations

### Bench Commands

Execute these via `.\tools\shell-erpnext.ps1` or inside container:

```bash
# Replace SITE_NAME with your actual site name
SITE_NAME="development.localhost"  # or "frontend" for production

# Database operations
bench --site $SITE_NAME migrate
bench --site $SITE_NAME console

# Cache management
bench --site $SITE_NAME clear-cache
bench --site $SITE_NAME clear-website-cache

# Configuration
bench --site $SITE_NAME set-config developer_mode 1
bench --site $SITE_NAME set-config developer_mode 0

# Build assets (after JS/CSS changes)
bench build --app qonto_connector

# App management
bench --site $SITE_NAME list-apps
bench --site $SITE_NAME install-app qonto_connector
bench --site $SITE_NAME uninstall-app qonto_connector

# Backup & restore
bench --site $SITE_NAME backup
bench --site $SITE_NAME backup --with-files
bench --site $SITE_NAME restore /path/to/backup.sql.gz

# View logs
bench --site $SITE_NAME show-log web
bench --site $SITE_NAME show-log worker
```

### Docker Commands

```powershell
# View running containers
docker ps

# View container logs
docker logs -f erpnext-qonto-backend-1

# Check container resource usage
docker stats

# Execute command in container
docker exec -it erpnext-qonto-backend-1 bash

# View Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# View compose services status
cd D:\ErpNext\erpnext-qonto
docker compose ps
```

### Development Workflow

```powershell
# After code changes in development mode:

# 1. Container automatically reloads Python code
# No action needed for .py files!

# 2. For JS/CSS changes, rebuild assets:
.\tools\shell-erpnext.ps1 -Command "bench build --app qonto_connector"

# 3. For DocType changes, run migrations:
.\tools\shell-erpnext.ps1 -Command "bench --site development.localhost migrate"

# 4. Clear cache if needed:
.\tools\shell-erpnext.ps1 -Command "bench --site development.localhost clear-cache"
```

### Production Workflow (pwd.yml)

```powershell
# After code changes in production mode:

# 1. Reinstall the app:
.\tools\install-qonto-app.ps1

# 2. Or manually copy and install:
cd D:\ErpNext\frappe_docker
docker cp D:\ErpNext\erpnext-qonto\qonto_connector backend:/home/frappe/frappe-bench/apps/qonto_connector
docker compose -f pwd.yml exec backend bench --site frontend migrate

# 3. Restart if needed:
docker compose -f pwd.yml restart backend

# 4. View logs:
docker compose -f pwd.yml logs -f backend
```

## 🐛 Troubleshooting

### Setup Issues

#### frappe_docker not found
```powershell
# Clone frappe_docker repository
git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker
```

#### Container won't start
```powershell
# Check Docker is running
docker info

# View container logs
.\tools\logs-erpnext.ps1 -Service backend -Follow

# Check for port conflicts
netstat -ano | findstr "8080 8000 9000"

# Recreate containers
.\tools\stop-erpnext.ps1 -Remove
.\tools\setup-erpnext-docker.ps1 -Mode production -Recreate
```

#### Service start fails
```powershell
# Check Docker disk space
docker system df

# Clean up unused resources
docker system prune -a

# Check logs
cd D:\ErpNext\frappe_docker
docker compose -f pwd.yml logs

# Try setup again
.\tools\setup-erpnext-docker.ps1 -Mode production
```

### Database Issues

#### Connection failures
```powershell
# Check database container
.\tools\logs-erpnext.ps1 -Service db

# Test database connection
docker exec -it $(docker ps -qf "name=db") mysqladmin ping -h localhost -u root -p123

# Restart database
docker compose --env-file .env -f docker-compose.yml -f compose.mariadb.yaml restart db
```

#### Migrations fail
```powershell
# Check database logs
.\tools\logs-erpnext.ps1 -Service db -Lines 200

# Run migrations manually with verbose output
.\tools\shell-erpnext.ps1 -Command "bench --site SITE_NAME migrate --verbose"

# If stuck, try rebuilding database from backup
.\tools\shell-erpnext.ps1 -Command "bench --site SITE_NAME restore /path/to/backup.sql.gz"
```

### Redis Issues

```powershell
# Test Redis connections
docker exec $(docker ps -qf "name=redis-cache") redis-cli ping
docker exec $(docker ps -qf "name=redis-queue") redis-cli ping

# View Redis logs
.\tools\logs-erpnext.ps1 -Service redis-cache
.\tools\logs-erpnext.ps1 -Service redis-queue

# Restart Redis
docker compose --env-file .env -f docker-compose.yml -f compose.redis.yaml restart redis-cache redis-queue
```

### App Installation Issues

#### Qonto Connector not found
```powershell
# Development mode: Check app path
Test-Path D:\ErpNext\erpnext-qonto\qonto_connector

# Production mode: Reinstall app
.\tools\install-qonto-app.ps1
```

#### Import errors after installation
```powershell
# Check if app is in apps.txt
.\tools\shell-erpnext.ps1 -Command "cat sites/apps.txt"

# Reinstall Python package
.\tools\shell-erpnext.ps1 -Command "pip install -e apps/qonto_connector"

# Clear cache and restart
.\tools\shell-erpnext.ps1 -Command "bench --site SITE_NAME clear-cache"
docker compose restart backend
```

### Performance Issues

#### Slow response times
```powershell
# Check container resource usage
docker stats

# Increase Docker resources in Docker Desktop settings
# Recommended: 4+ CPUs, 8+ GB RAM

# Check queue workers are running
docker ps | Select-String "queue"
```

#### Out of memory
```powershell
# Check Docker memory limits
docker system df

# Increase memory in Docker Desktop settings
# Restart Docker Desktop
```

### Port Conflicts

```powershell
# Find what's using the port
netstat -ano | findstr "8080"

# Change port in .env file
Add-Content .env "HTTP_PUBLISH_PORT=8090"

# Restart containers
.\tools\stop-erpnext.ps1
.\tools\start-erpnext.ps1
```

### Nuclear Option: Start Fresh

**⚠️ WARNING: This deletes ALL data!**

```powershell
# 1. Stop and remove containers (with confirmation)
.\tools\stop-erpnext.ps1 -Remove

# 2. Or do it manually
cd D:\ErpNext\frappe_docker
docker compose -f pwd.yml down -v

# 3. Remove Docker images (optional)
docker rmi frappe/erpnext:v15.81.2

# 4. Start fresh
.\tools\setup-erpnext-docker.ps1 -Mode production
```

### Getting Help

#### View all available containers
```powershell
docker ps -a
```

#### Check container health
```powershell
docker inspect CONTAINER_NAME | Select-String "Health"
```

#### Export logs for support
```powershell
# Export all logs
.\tools\logs-erpnext.ps1 -Lines 1000 > erpnext-logs.txt

# Export specific service
.\tools\logs-erpnext.ps1 -Service backend -Lines 500 > backend-logs.txt
```

## 🔐 Security Notes

### Development Mode
- Default passwords are weak (admin/123) - **DO NOT use in production**
- Developer mode is enabled - **DO NOT expose to internet**
- All ports are accessible from host - **Use firewall if needed**

### Production Mode
- Change default passwords immediately
- Use strong database passwords
- Consider using Docker secrets for sensitive data
- Set up HTTPS with Let's Encrypt (see frappe_docker docs)
- Restrict network access appropriately
- Regular backups are essential

### Best Practices
```powershell
# Use strong passwords
.\tools\setup-erpnext-docker.ps1 -Mode production `
    -AdminPassword "$(New-Guid)" `
    -DBPassword "$(New-Guid)"

# Backup regularly
.\tools\shell-erpnext.ps1 -Command "bench --site SITE_NAME backup --with-files"

# Keep images updated
docker pull frappe/erpnext:v15.81.2
```

## 📚 Additional Resources

### Official Documentation
- **frappe_docker:** https://github.com/frappe/frappe_docker
  - [Development Guide](https://github.com/frappe/frappe_docker/blob/main/docs/development.md)
  - [Production Setup](https://github.com/frappe/frappe_docker/blob/main/docs/single-compose-setup.md)
  - [Custom Apps](https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md)
- **ERPNext:** https://docs.erpnext.com/
- **Frappe Framework:** https://frappeframework.com/docs

### Community
- **ERPNext Forum:** https://discuss.erpnext.com/
- **Frappe GitHub:** https://github.com/frappe/frappe
- **ERPNext GitHub:** https://github.com/frappe/erpnext

### Related Files
- `apps.json` - Optional: App manifest for git-based installation
- `frappe_docker/pwd.yml` - Production compose file (official)
- `tools/*.ps1` - PowerShell management scripts

## 🎯 Quick Reference

### Most Used Commands

```powershell
# Development
code D:\ErpNext\frappe_docker  # Open in VSCode
# Then: Reopen in Container

# Production (using pwd.yml)
.\tools\setup-erpnext-docker.ps1 -Mode production  # Initial setup
.\tools\start-erpnext.ps1                          # Start containers
.\tools\stop-erpnext.ps1                           # Stop containers
.\tools\logs-erpnext.ps1 -Service backend -Follow  # View logs
.\tools\shell-erpnext.ps1                          # Open shell

# Or use docker compose directly
cd D:\ErpNext\frappe_docker
docker compose -f pwd.yml start
docker compose -f pwd.yml stop
docker compose -f pwd.yml logs -f backend

# App Management
.\tools\install-qonto-app.ps1                      # Install/reinstall app

# Inside Container (default site: frontend)
bench --site frontend migrate                      # Run migrations
bench --site frontend clear-cache                  # Clear cache
bench build --app qonto_connector                  # Rebuild assets
```

## 📄 License

MIT License - See LICENSE file for details

---

**Need Help?** Check the [Troubleshooting](#-troubleshooting) section or create an issue in the repository.


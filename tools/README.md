# ERPNext Docker Tools

PowerShell scripts for managing ERPNext v15 development environment with Docker.

## 📋 Prerequisites

- Windows 10/11 with PowerShell 7+
- Docker Desktop for Windows installed and running
- At least 8GB RAM available for Docker
- 20GB free disk space on D:\ drive

## 🚀 Quick Start

### 1. Initial Setup

Run the setup script to create and start all ERPNext containers:

```powershell
.\tools\setup-erpnext-docker.ps1
```

This will:
- Create directory structure on `D:\ErpNext`
- Generate `docker-compose.yml` and `.env` files
- Pull required Docker images
- Start all ERPNext services
- Initialize a new ERPNext site
- **Automatically install the Qonto Connector app**

**Parameters:**

- `-SiteName` - Custom site name (default: `erpnext.local`)
- `-AdminPassword` - Admin password (default: `admin`)
- `-MariaDBRootPassword` - Database root password (default: `erpnext123`)
- `-Pull` - Force pull latest images
- `-Recreate` - Recreate all containers

**Example:**
```powershell
.\tools\setup-erpnext-docker.ps1 -SiteName "dev.local" -AdminPassword "MySecurePass123" -Pull
```

### 2. Access ERPNext

After setup completes, access ERPNext at http://localhost:8080 and log in with:
- Username: `Administrator`
- Password: `admin` (or what you specified)

The Qonto Connector app is already installed and ready to configure!

### 3. (Optional) Manual App Reinstallation

If you need to reinstall or update the Qonto Connector app manually:

```powershell
.\tools\install-qonto-app.ps1
```

**Parameters:**
- `-SiteName` - Target site name (default: `erpnext.local`)

**Use this script for:**
- Reinstalling after app updates
- Troubleshooting installation issues
- Installing on existing sites created before auto-install feature

## 🔧 Management Scripts

### Start Containers

Start previously created containers:

```powershell
.\tools\start-erpnext.ps1
```

### Stop Containers

Stop running containers:

```powershell
# Stop containers (keep data)
.\tools\stop-erpnext.ps1

# Stop and remove containers (including volumes)
.\tools\stop-erpnext.ps1 -Remove
```

### View Logs

View container logs:

```powershell
# View all logs
.\tools\logs-erpnext.ps1

# Follow backend logs
.\tools\logs-erpnext.ps1 -Service backend -Follow

# Show last 500 lines
.\tools\logs-erpnext.ps1 -Lines 500
```

**Available services:**
- `backend` - ERPNext application server
- `frontend` - Nginx web server
- `mariadb` - Database
- `redis-cache`, `redis-queue`, `redis-socketio` - Redis instances
- `queue-default`, `queue-short`, `queue-long` - Queue workers
- `scheduler` - Scheduled tasks
- `socketio` - Real-time features

### Shell Access

Open a shell in the backend container:

```powershell
# Interactive shell
.\tools\shell-erpnext.ps1

# Execute specific command
.\tools\shell-erpnext.ps1 -Command "bench --site erpnext.local migrate"
```

## 📁 Directory Structure

```
D:\ErpNext\
├── sites\              # ERPNext sites data
├── logs\               # Application logs
├── apps\               # Custom apps
├── mariadb\            # Database backups
├── redis-cache\        # Redis cache data
├── redis-queue\        # Redis queue data
└── redis-socketio\     # Redis socketio data
```

## 🌐 Access Points

After setup, access ERPNext at:

- **Frontend:** http://localhost:8080
- **Backend API:** http://localhost:8000
- **SocketIO:** http://localhost:9000

**Default Credentials:**
- Username: `Administrator`
- Password: `admin` (or what you specified)

## 🔍 Useful Commands

### Bench Commands (via shell)

```bash
# Migrate database
bench --site erpnext.local migrate

# Clear cache
bench --site erpnext.local clear-cache

# Enable developer mode
bench --site erpnext.local set-config developer_mode 1

# Rebuild assets
bench build

# Create a new DocType
bench --site erpnext.local console

# View site info
bench --site erpnext.local list-apps

# Backup site
bench --site erpnext.local backup

# Restore site
bench --site erpnext.local restore /path/to/backup.sql.gz
```

### Docker Commands

```powershell
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# Check container resource usage
docker stats

# Remove unused images
docker image prune

# Remove all stopped containers
docker container prune

# View Docker disk usage
docker system df

# View compose services
docker compose -f ..\docker-compose.yml ps
```

## 🐛 Troubleshooting

### Containers won't start

```powershell
# Check Docker service
docker info

# View detailed logs
.\tools\logs-erpnext.ps1 -Follow

# Recreate containers
.\tools\setup-erpnext-docker.ps1 -Recreate
```

### Database connection issues

```powershell
# Check MariaDB health
docker exec -it erpnext-mariadb mysqladmin ping -h localhost -u root -perpnext123

# View MariaDB logs
.\tools\logs-erpnext.ps1 -Service mariadb
```

### Redis connection issues

```powershell
# Test Redis cache
docker exec -it erpnext-redis-cache redis-cli ping

# Test Redis queue
docker exec -it erpnext-redis-queue redis-cli ping
```

### Port conflicts

If ports 8080, 8000, or 9000 are already in use:

1. Edit `.env` file and change port numbers
2. Restart containers: `.\tools\stop-erpnext.ps1` then `.\tools\start-erpnext.ps1`

### Clear all data and start fresh

```powershell
# Stop and remove everything
.\tools\stop-erpnext.ps1 -Remove

# Remove data directory (CAUTION: This deletes all data!)
Remove-Item -Path "D:\ErpNext" -Recurse -Force

# Remove docker-compose.yml and .env
Remove-Item docker-compose.yml, .env

# Run setup again
.\tools\setup-erpnext-docker.ps1
```

## 🔄 Development Workflow

### After code changes

```powershell
# 1. Restart backend container
docker-compose restart backend

# 2. Clear cache
.\tools\shell-erpnext.ps1 -Command "bench --site erpnext.local clear-cache"

# 3. Rebuild assets (if JS/CSS changed)
.\tools\shell-erpnext.ps1 -Command "bench build"
```

### Run migrations after DocType changes

```powershell
.\tools\shell-erpnext.ps1 -Command "bench --site erpnext.local migrate"
```

### Run tests

```powershell
# All tests
.\tools\shell-erpnext.ps1 -Command "bench --site erpnext.local run-tests --app qonto_connector"

# Specific test file
.\tools\shell-erpnext.ps1 -Command "bench --site erpnext.local run-tests qonto_connector.tests.test_client"
```

## 📝 Notes

- The Qonto Connector app is mounted from your local workspace, so changes are reflected immediately
- Use developer mode for faster development (already enabled by setup script)
- Logs are persistent in `D:\ErpNext\logs`
- Database backups can be placed in `D:\ErpNext\mariadb`

## 🆘 Support

For issues specific to:
- **ERPNext:** https://discuss.erpnext.com/
- **Qonto Connector:** Create an issue in the project repository
- **Docker:** https://docs.docker.com/

## 📄 License

MIT License - See LICENSE file for details


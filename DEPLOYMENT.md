# ERPNext Qonto Connector - Deployment Guide

This guide explains deployment strategies for the ERPNext Qonto Connector using Docker.

**Production deployments use the official `frappe_docker/pwd.yml` configuration.**

## Table of Contents

- [Production Deployment (pwd.yml)](#production-deployment-pwdyml)
- [Development Setup](#development-setup)
- [Volume Management](#volume-management)
- [Backup and Restore](#backup-and-restore)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

## Production Deployment (pwd.yml)

### Overview

For production deployments, use the **official frappe_docker `pwd.yml`** configuration located at:
```
D:\ErpNext\frappe_docker\pwd.yml
```

This configuration is:
- ✅ Production-tested by the Frappe community
- ✅ Uses Docker named volumes for optimal performance
- ✅ Includes all required services (MariaDB, Redis, queues, scheduler)
- ✅ Maintained and updated with Frappe releases

### Quick Start

1. **Navigate to frappe_docker directory:**
   ```bash
   cd D:\ErpNext\frappe_docker
   ```

2. **Start all services:**
   ```bash
   docker compose -f pwd.yml up -d
   ```

3. **Wait for site creation** (this happens automatically):
   ```bash
   docker compose -f pwd.yml logs -f create-site
   ```
   Wait until you see: "Site frontend has been created successfully"

4. **Install qonto_connector app:**
   ```bash
   # Enter the backend container
   docker compose -f pwd.yml exec backend bash
   
   # Navigate to bench directory
   cd /home/frappe/frappe-bench
   
   # Install from git
   bench get-app https://github.com/YOUR-USERNAME/qonto_connector
   bench --site frontend install-app qonto_connector
   bench --site frontend migrate
   
   # Exit container
   exit
   ```

5. **Access ERPNext:**
   - URL: http://localhost:8080
   - Username: Administrator
   - Password: admin

### Configuration Details

The `pwd.yml` configuration includes:

- **Database**: MariaDB 10.6 with persistent volume
- **Cache**: Redis (separate for cache and queue)
- **Site Name**: frontend (default)
- **Default Credentials**: admin/admin
- **Ports**: 8080 (HTTP)
- **Volumes**: Docker named volumes for optimal performance

### Customizing pwd.yml Configuration

If you need to customize settings, you can override them with environment variables or a separate override file:

```bash
# Create a custom override file
cat > docker-compose.override.yml <<EOF
version: "3"
services:
  frontend:
    ports:
      - "80:8080"  # Use port 80 instead of 8080
  db:
    environment:
      MYSQL_ROOT_PASSWORD: your_secure_password
      MARIADB_ROOT_PASSWORD: your_secure_password
EOF

# Deploy with override
docker compose -f pwd.yml -f docker-compose.override.yml up -d
```

## Development Setup

### Using Bind Mounts (Current Configuration)

1. **Run the setup script:**
   ```powershell
   .\tools\setup-erpnext-docker.ps1
   ```

2. **The script automatically configures:**
   - Creates `D:\ErpNext\sites` directory
   - Sets `SITES_DIR` in `.env` file
   - Starts containers with bind mounts

3. **Access files directly:**
   ```powershell
   # View site directory
   ls D:\ErpNext\sites\erpnext.local
   
   # View logs
   cat D:\ErpNext\sites\erpnext.local\logs\web.log
   
   # Backup
   Copy-Item -Recurse D:\ErpNext\sites D:\Backups\sites-$(Get-Date -Format 'yyyyMMdd')
   ```

## Installing Qonto Connector on Production

### Method 1: Install from Git (Recommended)

```bash
# Enter backend container
docker compose -f pwd.yml exec backend bash

# Install app from git
cd /home/frappe/frappe-bench
bench get-app https://github.com/YOUR-USERNAME/qonto_connector
bench --site frontend install-app qonto_connector
bench --site frontend migrate
bench --site frontend clear-cache
```

### Method 2: Install from Private Repository

```bash
# Enter backend container
docker compose -f pwd.yml exec backend bash

# Install with PAT embedded
cd /home/frappe/frappe-bench
bench get-app https://{{YOUR_PAT}}@github.com/YOUR-ORG/qonto_connector.git
bench --site frontend install-app qonto_connector
bench --site frontend migrate
```

### Method 3: Copy Local Directory (Development/Testing)

```bash
# Copy app to container
docker cp D:\ErpNext\erpnext-qonto backend:/home/frappe/frappe-bench/apps/qonto_connector

# Enter container and install
docker compose -f pwd.yml exec backend bash
cd /home/frappe/frappe-bench
bench --site frontend install-app qonto_connector
bench --site frontend migrate
```

## Volume Management

### List Volumes

```bash
# List all volumes
docker volume ls

# Find ERPNext volumes
docker volume ls | grep erpnext
```

### Inspect Volume

```bash
# Get detailed information
docker volume inspect erpnext-qonto_sites

# Find mount point
docker volume inspect erpnext-qonto_sites | grep Mountpoint
```

### Remove Volume (⚠️ DANGER - Deletes all data!)

```bash
# Stop containers first
docker compose down

# Remove volume
docker volume rm erpnext-qonto_sites

# Or remove all unused volumes
docker volume prune
```

## Backup and Restore

### Backup Bind Mount (Development)

**Windows:**
```powershell
# Simple copy
Copy-Item -Recurse D:\ErpNext\sites D:\Backups\sites-$(Get-Date -Format 'yyyyMMdd')

# Compressed backup
Compress-Archive -Path D:\ErpNext\sites -DestinationPath "D:\Backups\sites-$(Get-Date -Format 'yyyyMMdd').zip"
```

**Linux/Mac:**
```bash
# Tar backup
tar czf ~/backups/sites-$(date +%Y%m%d).tar.gz /path/to/sites

# Rsync backup
rsync -av /path/to/sites/ ~/backups/sites/
```

### Backup Named Volume (Production)

**Using Docker:**
```bash
# Backup to tar.gz
docker run --rm \
  -v erpnext-qonto_sites:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/sites-$(date +%Y%m%d).tar.gz -C /data .

# Backup to another volume
docker run --rm \
  -v erpnext-qonto_sites:/source:ro \
  -v backup_volume:/backup \
  alpine cp -a /source/. /backup/
```

**Windows PowerShell:**
```powershell
# Create backup directory
mkdir -Force backups

# Backup volume
docker run --rm `
  -v erpnext-qonto_sites:/data `
  -v ${PWD}/backups:/backup `
  alpine tar czf /backup/sites-$(Get-Date -Format 'yyyyMMdd').tar.gz -C /data .
```

### Restore Bind Mount

**Windows:**
```powershell
# From directory
Copy-Item -Recurse D:\Backups\sites-20250106\* D:\ErpNext\sites

# From zip
Expand-Archive -Path D:\Backups\sites-20250106.zip -DestinationPath D:\ErpNext\sites
```

**Linux/Mac:**
```bash
# From tar.gz
tar xzf ~/backups/sites-20250106.tar.gz -C /path/to/sites
```

### Restore Named Volume

```bash
# Stop containers
docker compose down

# Remove old volume (optional)
docker volume rm erpnext-qonto_sites

# Restore from backup
docker run --rm \
  -v erpnext-qonto_sites:/data \
  -v $(pwd)/backups:/backup \
  alpine tar xzf /backup/sites-20250106.tar.gz -C /data

# Start containers
docker compose up -d
```

**Windows PowerShell:**
```powershell
# Stop containers
docker compose down

# Restore volume
docker run --rm `
  -v erpnext-qonto_sites:/data `
  -v ${PWD}/backups:/backup `
  alpine tar xzf /backup/sites-20250106.tar.gz -C /data

# Start containers
docker compose up -d
```

## Migration Between Strategies

### From Bind Mount to Named Volume

1. **Stop containers:**
   ```bash
   docker compose down
   ```

2. **Create and populate named volume:**
   ```bash
   # Create volume
   docker volume create erpnext_sites_prod
   
   # Copy data from bind mount to volume
   docker run --rm \
     -v /path/to/sites:/source:ro \
     -v erpnext_sites_prod:/destination \
     alpine cp -a /source/. /destination/
   ```

   **Windows:**
   ```powershell
   docker volume create erpnext_sites_prod
   
   docker run --rm `
     -v D:/ErpNext/sites:/source:ro `
     -v erpnext_sites_prod:/destination `
     alpine sh -c "cp -a /source/. /destination/"
   ```

3. **Update docker-compose.yml or use docker-compose.prod.yml:**
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
   ```

### From Named Volume to Bind Mount

1. **Stop containers:**
   ```bash
   docker compose down
   ```

2. **Create bind mount directory and copy data:**
   ```bash
   # Create directory
   mkdir -p /path/to/sites
   
   # Copy data from volume to bind mount
   docker run --rm \
     -v erpnext-qonto_sites:/source:ro \
     -v /path/to/sites:/destination \
     alpine cp -a /source/. /destination/
   ```

   **Windows:**
   ```powershell
   # Create directory
   mkdir -Force D:\ErpNext\sites
   
   # Copy data
   docker run --rm `
     -v erpnext-qonto_sites:/source:ro `
     -v D:/ErpNext/sites:/destination `
     alpine sh -c "cp -a /source/. /destination/"
   ```

3. **Update .env file:**
   ```bash
   SITES_DIR=D:\ErpNext\sites
   ```

4. **Start containers:**
   ```bash
   docker compose up -d
   ```

## Best Practices

### Production
- ✅ **Use frappe_docker pwd.yml** - Production-tested configuration
- ✅ **Named volumes** - Better performance and Docker-managed
- ✅ **Regular backups** - Automated backup scripts
- ✅ **Monitor logs** - Use `docker compose -f pwd.yml logs`
- ✅ **Secure credentials** - Change default passwords
- ✅ **Regular updates** - Keep frappe_docker up to date

### Development
- ✅ Use local setup scripts for development
- ✅ Keep development separate from production
- ✅ Test migrations before deploying

### Staging
- ✅ Use pwd.yml to mirror production
- ✅ Test with production-like data
- ✅ Validate backups and restores

## Troubleshooting

### Volume permission issues
```bash
# Check volume ownership
docker run --rm -v erpnext-qonto_sites:/data alpine ls -la /data

# Fix permissions (if needed)
docker run --rm -v erpnext-qonto_sites:/data alpine chown -R 1000:1000 /data
```

### Volume not mounting
```bash
# Check if volume exists
docker volume ls

# Inspect volume
docker volume inspect erpnext-qonto_sites

# Check container mounts
docker inspect <container-name> | grep Mounts -A 20
```

### Disk space issues
```bash
# Check volume size
docker system df -v

# Clean up unused volumes
docker volume prune
```

## Additional Resources

- [Docker Volumes Documentation](https://docs.docker.com/storage/volumes/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Frappe Docker Documentation](https://github.com/frappe/frappe_docker)
- [ERPNext Documentation](https://docs.erpnext.com/)

## Summary

| Aspect | Production (pwd.yml) | Development |
|--------|---------------------|-------------|
| **Configuration** | frappe_docker/pwd.yml | Local setup scripts |
| **Volumes** | Docker named volumes | Bind mounts or volumes |
| **Performance** | High | Medium |
| **Maintenance** | Community-maintained | Custom |
| **Updates** | Pull latest frappe_docker | Manual updates |
| **Best for** | Production deployments | Local development |

**Recommendation**: Always use `frappe_docker/pwd.yml` for production deployments to ensure compatibility and leverage community best practices.

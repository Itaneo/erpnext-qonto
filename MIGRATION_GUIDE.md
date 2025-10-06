# Migration Guide: Updated Docker Deployment

## 🎯 What Changed

The tools in this repository have been completely rewritten to use the **official frappe_docker** deployment methods instead of a custom Docker Compose setup.

## 🏗️ New Architecture

### Before
- Custom `docker-compose.yml` with manually configured services
- Single deployment approach
- Limited flexibility

### After
- **Official frappe_docker** integration
- **Two deployment modes:** Development and Production
- Follows Frappe best practices
- Better maintainability and community support

## 🚀 Two Deployment Modes

### Development Mode 🛠️
- **Purpose:** Active development with live code reloading
- **Method:** VSCode devcontainer
- **Benefits:**
  - Full debugging support
  - Python code auto-reloads
  - Apps mounted from local filesystem
  - Ideal for development and testing

### Production Mode 🚀
- **Purpose:** Production-like environment
- **Method:** Custom Docker image with apps baked in
- **Benefits:**
  - Optimized performance
  - Stable, reproducible deployments
  - Easy to push to registries
  - Ideal for staging and production

## 📋 Prerequisites

Before using the new scripts, you need:

```powershell
# Clone frappe_docker repository
git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker
```

## 🔄 Migrating from Old Setup

If you were using the old custom setup:

### Option 1: Start Fresh (Recommended)

```powershell
# 1. Backup your data
.\tools\shell-erpnext.ps1 -Command "bench --site YOUR_SITE backup --with-files"

# 2. Stop old containers
docker compose down -v

# 3. Remove old files
Remove-Item docker-compose.yml, .env

# 4. Setup with new method
.\tools\setup-erpnext-docker.ps1 -Mode production

# 5. Restore your data
.\tools\shell-erpnext.ps1 -Command "bench --site frontend restore /path/to/backup.sql.gz"
```

### Option 2: Manual Migration

If you want to keep your existing data:

1. Export your current database and files
2. Follow "Option 1: Start Fresh" above
3. Import your data into the new setup

## 📦 Updated Scripts

### Main Setup Script
**`setup-erpnext-docker.ps1`**
- Now supports `-Mode` parameter (development/production)
- Integrates with frappe_docker
- Uses official images for production (no custom building)
- Auto-configures based on mode

### Deprecated Script
**`build-prod-image.ps1`** ⚠️ DEPRECATED
- No longer recommended - use official images instead
- Kept for reference only
- Uses official frappe_docker build process

### Updated Scripts
All management scripts now work with both deployment modes:
- `start-erpnext.ps1` - Uses `.env` and compose overrides
- `stop-erpnext.ps1` - Works with official compose structure
- `logs-erpnext.ps1` - Auto-detects compose configuration
- `shell-erpnext.ps1` - Smart container detection
- `install-qonto-app.ps1` - Auto-detects deployment mode

## 🚦 Quick Start Examples

### Development Setup
```powershell
# One command to prepare devcontainer config
.\tools\setup-erpnext-docker.ps1 -Mode development

# Then open in VSCode and reopen in container
code D:\ErpNext\frappe_docker

# Inside container, setup bench (instructions shown by script)
```

### Production Setup
```powershell
# One command for full setup (builds image, starts containers, creates site)
.\tools\setup-erpnext-docker.ps1 -Mode production

# Access at http://localhost:8080
```

### Custom Production Setup
```powershell
# With custom parameters
.\tools\setup-erpnext-docker.ps1 `
    -Mode production `
    -SiteName "mycompany" `
    -AdminPassword "SecurePassword123!" `
    -DBPassword "AnotherSecurePass456!"
```

## 📚 Key Files

### Generated/Modified Files

**Development Mode:**
- `D:\ErpNext\frappe_docker\.devcontainer\` - VSCode devcontainer config

**Production Mode:**
- `docker-compose.yml` - Main compose file (copied from frappe_docker)
- `.env` - Environment variables
- `compose.mariadb.yaml` - MariaDB service override
- `compose.redis.yaml` - Redis services override
- `compose.noproxy.yaml` - No-proxy configuration
- `apps.json` - Apps manifest for image building

### Source Files (Not Changed)
- `qonto_connector/` - Your app source code (unchanged)
- `tools/*.ps1` - Management scripts (rewritten but same interface)

## 🔍 What to Check After Migration

### Verify Services Running
```powershell
docker ps
# Should see: backend, frontend, db, redis-cache, redis-queue, queue-*, scheduler, websocket
```

### Verify Site Access
```powershell
# Development: http://development.localhost:8000
# Production: http://localhost:8080

# Login: Administrator / admin (or your custom password)
```

### Verify Qonto Connector Installed
```powershell
.\tools\shell-erpnext.ps1 -Command "bench --site YOUR_SITE list-apps"
# Should include: frappe, erpnext, qonto_connector
```

## 🆘 Common Issues

### "frappe_docker not found"
```powershell
git clone https://github.com/frappe/frappe_docker D:\ErpNext\frappe_docker
```

### Port conflicts
```powershell
# Check what's using ports
netstat -ano | findstr "8080 8000"

# Change port in .env
echo "HTTP_PUBLISH_PORT=8090" >> .env
```

### Container not starting
```powershell
# View logs
.\tools\logs-erpnext.ps1 -Service backend -Follow

# Check Docker resources (need 4GB+ RAM, 20GB+ disk)
docker system df
```

## 📖 Documentation

- **Complete documentation:** `tools/README.md`
- **Frappe Docker docs:** https://github.com/frappe/frappe_docker/tree/main/docs
- **Development guide:** `D:\ErpNext\frappe_docker\docs\development.md`
- **Production guide:** `D:\ErpNext\frappe_docker\docs\single-compose-setup.md`

## ✅ Benefits of New Approach

1. **Official Support**: Uses standard frappe_docker methods
2. **Community**: Easy to get help from Frappe community
3. **Updates**: Easy to update to new Frappe/ERPNext versions
4. **Flexibility**: Switch between dev and prod easily
5. **Documentation**: Extensive official documentation available
6. **Best Practices**: Follows Frappe's recommended deployment methods

## 🎓 Learning Resources

- Official frappe_docker development guide
- ERPNext Docker deployment documentation
- Frappe Framework documentation
- Community forum: https://discuss.erpnext.com/

## 💡 Tips

### Development Mode
- Use `bench start` inside container for live reloading
- Python code changes reload automatically
- For JS/CSS: run `bench build --app qonto_connector`
- For DocTypes: run `bench migrate`

### Production Mode
- After code changes: rebuild image with `.\tools\build-prod-image.ps1`
- Then restart: `.\tools\stop-erpnext.ps1` && `.\tools\start-erpnext.ps1`
- Use strong passwords (not defaults!)
- Set up regular backups

## 🔐 Security Reminder

### Development
- **DO NOT** expose development mode to internet
- Default passwords are weak by design

### Production
- Change all default passwords immediately
- Use Docker secrets for sensitive data
- Set up HTTPS (see frappe_docker docs)
- Configure firewall rules
- Regular backups are essential

---

**Questions?** Check `tools/README.md` or create an issue in the repository.



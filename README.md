# Qonto Connector for ERPNext v15

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.10%2B-blue)](https://www.python.org/downloads/)
[![Frappe Version](https://img.shields.io/badge/frappe-v15-orange)](https://frappeframework.com/)
[![ERPNext Version](https://img.shields.io/badge/erpnext-v15-orange)](https://erpnext.com/)

**Qonto Connector** is a production-ready Frappe app that seamlessly syncs Qonto bank transactions into ERPNext v15, supporting multi-company and multi-account setups with API Key authentication.

## 🎯 Features

- ✅ **ERPNext v15 Compatible** - Built specifically for ERPNext v15 / Frappe v15
- 🔐 **API Key Authentication** - Secure authentication using Qonto API keys (no OAuth complexity)
- 🏢 **Multi-Company Support** - Manage transactions across multiple companies
- 💼 **Multi-Account Support** - Sync multiple Qonto bank accounts simultaneously
- 🔄 **Automated Sync** - Scheduled synchronization every 15 minutes (configurable)
- 📊 **Transaction Management** - Automatic creation of Bank Transaction records
- 🛡️ **Idempotent Operations** - Prevents duplicate transactions
- 📝 **Comprehensive Logging** - Detailed sync logs for debugging and auditing
- 🐳 **Docker-First** - Ready for containerized deployments
- 🧪 **Test Coverage** - Comprehensive test suite included

## 📋 Table of Contents

- [Requirements](#-requirements)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [API Endpoints](#-api-endpoints)
- [Development](#-development)
- [Testing](#-testing)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## 🔧 Requirements

- **Python**: 3.10 or higher
- **Frappe Framework**: v15.x
- **ERPNext**: v15.x
- **Qonto Account**: Business account with API access

### Dependencies

- `requests>=2.28.0,<3.0.0` - HTTP library for API calls

## 📦 Installation

### Method 1: Using bench (Recommended)

```bash
# Navigate to your Frappe bench directory
cd ~/frappe-bench

# Get the app from repository
bench get-app https://github.com/itaneo/qonto-connector.git

# Install the app on your site
bench --site your-site-name install-app qonto_connector

# Restart bench
bench restart
```

### Method 2: Manual Installation

```bash
# Clone the repository
cd ~/frappe-bench/apps
git clone https://github.com/itaneo/qonto-connector.git

# Install dependencies
cd qonto-connector
pip install -r requirements.txt

# Install on site
cd ~/frappe-bench
bench --site your-site-name install-app qonto_connector

# Migrate
bench --site your-site-name migrate

# Restart
bench restart
```

### Method 3: Docker Installation

If you're using the official Frappe Docker setup:

```bash
# Add to your apps.json
{
  "qonto_connector": {
    "url": "https://github.com/itaneo/qonto-connector.git",
    "branch": "main"
  }
}

# Rebuild your containers
docker-compose up -d --build
```

## ⚙️ Configuration

### Step 1: Get Qonto API Credentials

1. Log in to your [Qonto account](https://app.qonto.com)
2. Navigate to **Settings** → **API & Integrations**
3. Create a new API key with the following permissions:
   - `transactions:read`
   - `organization:read`
4. Save your **Organization Slug** (Login) and **Secret Key**

### Step 2: Configure Qonto Settings

1. Open ERPNext and navigate to:
   ```
   Home → Qonto Connector → Qonto Settings
   ```

2. Fill in the configuration:
   - **Environment**: Choose `Sandbox` for testing or `Production` for live data
   - **API Login**: Your Qonto organization slug
   - **API Secret Key**: Your Qonto secret key
   - **Sync Interval**: How often to sync (default: 15 minutes)
   - **Default Lookback Days**: How many days to look back on first sync (default: 90)

3. Click **Test Connection** to verify credentials

### Step 3: Set Up Account Mappings

1. After successful connection, click **Fetch Accounts** to see your Qonto bank accounts

2. In the **Account Mappings** table, add a row for each account you want to sync:
   - **Company**: Select the ERPNext company
   - **Qonto Account ID**: The Qonto account slug (from Fetch Accounts)
   - **ERPNext Bank Account**: The corresponding Bank Account in ERPNext
   - **Active**: Check to enable syncing for this account

3. Click **Save**

### Step 4: Verify Setup

1. Click **Sync Now** to trigger an immediate synchronization
2. Navigate to **Banking** → **Bank Transaction** to see synced transactions
3. Check **Qonto Sync Log** for detailed sync information

## 🚀 Usage

### Automatic Synchronization

Once configured, Qonto Connector automatically syncs transactions every 15 minutes (configurable). No manual intervention is required.

### Manual Synchronization

To manually trigger a sync:

1. Navigate to **Qonto Settings**
2. Click **Actions** → **Sync Now**
3. The sync will run in the background

### View Sync Status

1. Navigate to **Qonto Settings**
2. Click **Actions** → **View Sync Status**
3. See current sync status and recent logs

### Managing Transactions

Synced transactions appear in:
```
Home → Banking → Bank Transaction
```

Each transaction includes:
- **Date**: Transaction posting date
- **Bank Account**: Linked ERPNext bank account
- **Company**: Associated company
- **Description**: Transaction details
- **Deposit/Withdrawal**: Transaction amount
- **Qonto Transaction ID**: Unique identifier (custom field)
- **Qonto Data**: Raw API response (custom field, hidden)

### Reconciliation

Use ERPNext's standard bank reconciliation tools:
```
Home → Banking → Bank Reconciliation Tool
```

The connector creates **draft** Bank Transaction records. You can:
1. Review and verify transactions
2. Match with payment entries
3. Submit transactions after reconciliation

## 🔌 API Endpoints

The app exposes the following whitelisted API endpoints:

### Test Connection

```python
frappe.call({
    method: 'qonto_connector.api.v1.test_connection',
    callback: function(r) {
        console.log(r.message);
    }
});
```

### Fetch Accounts

```python
frappe.call({
    method: 'qonto_connector.api.v1.fetch_accounts',
    callback: function(r) {
        console.log(r.message.accounts);
    }
});
```

### Trigger Sync

```python
frappe.call({
    method: 'qonto_connector.api.v1.sync_now',
    callback: function(r) {
        console.log(r.message);
    }
});
```

### Get Sync Status

```python
frappe.call({
    method: 'qonto_connector.api.v1.get_sync_status',
    callback: function(r) {
        console.log(r.message);
    }
});
```

## 💻 Development

### Project Structure

```
qonto_connector/
├── qonto/                      # Core business logic
│   ├── client.py              # Qonto API client
│   ├── sync.py                # Sync engine
│   ├── mapping.py             # Transaction mapping
│   ├── utils.py               # Utility functions
│   ├── constants.py           # Constants
│   └── exceptions.py          # Custom exceptions
├── api/                       # REST API endpoints
│   └── v1.py                  # API v1
├── qonto_connector/           # Module directory
│   └── doctype/               # DocTypes
│       ├── qonto_settings/
│       ├── qonto_account_mapping/
│       └── qonto_sync_log/
├── config/                    # App configuration
├── public/                    # Static assets
│   ├── css/
│   ├── js/
│   └── images/
├── tests/                     # Test suite
└── hooks.py                   # Frappe hooks
```

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/itaneo/qonto-connector.git
cd qonto-connector

# Create virtual environment (optional)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Install in development mode
cd ~/frappe-bench
bench --site development.localhost install-app qonto_connector

# Enable developer mode
bench --site development.localhost set-config developer_mode 1

# Watch for changes
bench watch
```

### Code Style

This project follows standard Python coding conventions:

- **PEP 8** style guide
- **Type hints** for better code clarity
- **Docstrings** for all public functions and classes
- **Black** for code formatting (line length: 100)
- **isort** for import sorting

```bash
# Format code
black qonto_connector --line-length 100
isort qonto_connector --profile black
```

## 🧪 Testing

### Run Tests

```bash
# Run all tests
cd ~/frappe-bench
bench --site test_site run-tests --app qonto_connector

# Run specific test file
bench --site test_site run-tests --app qonto_connector --module qonto_connector.tests.test_client

# Run with coverage
bench --site test_site run-tests --app qonto_connector --coverage
```

### Test Structure

- `tests/conftest.py` - Pytest fixtures
- `tests/test_client.py` - API client tests
- `tests/test_sync.py` - Sync engine tests
- `tests/test_mapping.py` - Transaction mapping tests

## 🔍 Troubleshooting

### Connection Issues

**Problem**: "Invalid API credentials" error

**Solution**:
1. Verify your API Login (organization slug) is correct
2. Ensure API Secret Key is valid and not expired
3. Check you're using the correct environment (Sandbox vs Production)

### Sync Not Working

**Problem**: Transactions not syncing automatically

**Solution**:
1. Check if scheduler is enabled: `bench --site your-site enable-scheduler`
2. Verify account mappings are **Active**
3. Check **Qonto Sync Log** for error messages
4. Ensure Bank Account is linked correctly

### Duplicate Transactions

**Problem**: Same transaction appearing multiple times

**Solution**:
- The app includes duplicate prevention. If you see duplicates:
  1. Check if transactions have different Qonto Transaction IDs
  2. Verify the `qonto_id` custom field exists on Bank Transaction
  3. Run: `bench --site your-site migrate`

### Rate Limiting

**Problem**: "Rate limit exceeded" errors

**Solution**:
- Qonto API has rate limits. The connector includes automatic retry logic.
- If persistent, increase **Sync Interval** in Qonto Settings

### Missing Custom Fields

**Problem**: Custom fields not appearing on Bank Transaction

**Solution**:
```bash
cd ~/frappe-bench
bench --site your-site migrate
bench --site your-site clear-cache
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Reporting Issues

1. Check [existing issues](https://github.com/itaneo/qonto-connector/issues)
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (ERPNext version, OS, etc.)

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Add tests for new functionality
5. Run tests: `bench --site test_site run-tests --app qonto_connector`
6. Commit your changes: `git commit -m 'Add amazing feature'`
7. Push to branch: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Development Guidelines

- Follow existing code style and patterns
- Add docstrings to all public functions
- Include type hints
- Write tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Frappe Framework](https://frappeframework.com/)
- Integrates with [Qonto](https://qonto.com/) banking platform
- Developed by [Itanéo](https://itaneo.com/)

## 📞 Support

- **Documentation**: [GitHub Wiki](https://github.com/itaneo/qonto-connector/wiki)
- **Issues**: [GitHub Issues](https://github.com/itaneo/qonto-connector/issues)
- **Email**: support@itaneo.com

## 🗺️ Roadmap

- [ ] Auto-submit transactions after reconciliation
- [ ] Support for attachment downloads
- [ ] Multi-currency support enhancements
- [ ] Webhook integration for real-time sync
- [ ] Advanced filtering options
- [ ] Transaction categorization rules
- [ ] Custom field mapping

## 📈 Changelog

### Version 1.0.0 (2025-10-04)

- ✨ Initial release
- 🔐 API Key authentication
- 🏢 Multi-company support
- 💼 Multi-account support
- 🔄 Automated sync engine
- 📊 Bank transaction creation
- 📝 Sync logging
- 🧪 Test suite

---

**Made with ❤️ by [Itanéo](https://itaneo.com/)**

For production deployments, ensure you:
1. Use Production environment
2. Keep API credentials secure
3. Regularly review sync logs
4. Monitor transaction creation
5. Keep the app updated

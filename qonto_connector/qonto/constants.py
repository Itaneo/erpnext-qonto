# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Constants for Qonto Connector"""

# API Configuration
QONTO_API_VERSION = "v2"
QONTO_PRODUCTION_URL = "https://thirdparty.qonto.com/v2/"
QONTO_SANDBOX_URL = "https://thirdparty-sandbox.qonto.com/v2/"

# API Endpoints
ENDPOINTS = {
    "organization": "organization",
    "transactions": "transactions",
}

# Transaction Statuses
TRANSACTION_STATUS_PENDING = "pending"
TRANSACTION_STATUS_SETTLED = "settled"
TRANSACTION_STATUS_DECLINED = "declined"
TRANSACTION_STATUS_CANCELED = "canceled"

# Transaction Sides
TRANSACTION_SIDE_DEBIT = "debit"
TRANSACTION_SIDE_CREDIT = "credit"

# Sync Configuration
DEFAULT_SYNC_INTERVAL_MINUTES = 15
DEFAULT_LOOKBACK_DAYS = 90
DEFAULT_PAGE_SIZE = 100
MAX_PAGE_SIZE = 100

# Rate Limiting
DEFAULT_RETRY_AFTER = 60  # seconds
MAX_RETRIES = 3
BACKOFF_FACTOR = 1

# Cache Keys
CACHE_KEY_SYNC_RUNNING = "qonto_sync_running"
CACHE_KEY_SETTINGS = "qonto_settings"

# Sync Lock Timeout (seconds)
SYNC_LOCK_TIMEOUT = 900  # 15 minutes

# Custom Field Names
CUSTOM_FIELD_QONTO_ID = "qonto_id"
CUSTOM_FIELD_QONTO_DATA = "qonto_data"

# Role Names
ROLE_QONTO_MANAGER = "Qonto Manager"


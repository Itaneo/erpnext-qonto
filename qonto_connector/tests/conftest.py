# Copyright (c) 2025, Itanéo and Contributors
# See license.txt

"""Pytest configuration for Qonto Connector tests"""

import pytest
import frappe
from unittest.mock import Mock, patch


@pytest.fixture
def qonto_settings():
    """Create test Qonto Settings"""
    if frappe.db.exists("Qonto Settings", "Qonto Settings"):
        doc = frappe.get_doc("Qonto Settings", "Qonto Settings")
        doc.delete()
    
    settings = frappe.get_doc({
        "doctype": "Qonto Settings",
        "environment": "Sandbox",
        "api_login": "test-org",
        "api_secret_key": "test-secret-key",
        "poll_interval_minutes": 15,
        "default_sync_lookback_days": 90,
        "connected": False
    })
    settings.insert(ignore_permissions=True)
    frappe.db.commit()
    
    yield settings
    
    # Cleanup
    if frappe.db.exists("Qonto Settings", "Qonto Settings"):
        doc = frappe.get_doc("Qonto Settings", "Qonto Settings")
        doc.delete()
    frappe.db.commit()


@pytest.fixture
def mock_qonto_client():
    """Mock Qonto API client"""
    with patch("qonto_connector.qonto.client.QontoClient") as mock_client:
        mock_instance = Mock()
        mock_client.return_value = mock_instance
        
        # Mock organization response
        mock_instance.get_organization.return_value = {
            "slug": "test-org",
            "name": "Test Organization",
            "legal_name": "Test Organization Inc.",
            "bank_accounts": []
        }
        
        # Mock accounts response
        mock_instance.list_accounts.return_value = []
        
        # Mock transactions iterator
        mock_instance.iter_transactions.return_value = iter([])
        
        yield mock_instance


@pytest.fixture
def sample_transaction():
    """Sample Qonto transaction data"""
    return {
        "transaction_id": "test-tx-001",
        "amount": -50.00,
        "currency": "EUR",
        "side": "debit",
        "status": "settled",
        "settled_at": "2025-10-04T10:00:00Z",
        "emitted_at": "2025-10-04T09:00:00Z",
        "label": "Test Transaction",
        "reference": "REF001",
        "counterparty_name": "Test Merchant",
        "operation_type": "card",
        "attachment_ids": []
    }


@pytest.fixture
def sample_bank_account():
    """Sample Qonto bank account data"""
    return {
        "slug": "test-account-001",
        "name": "Main Account",
        "iban": "FR7612345678901234567890123",
        "bic": "QNTOFRP1XXX",
        "currency": "EUR",
        "balance": 1000.00,
        "balance_cents": 100000,
        "status": "active"
    }


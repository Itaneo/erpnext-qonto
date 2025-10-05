# Copyright (c) 2025, Itanéo and Contributors
# See license.txt

"""Tests for sync engine"""

import pytest
import frappe
from unittest.mock import Mock, patch, MagicMock
from qonto_connector.qonto.sync import (
    schedule_all_syncs,
    sync_all_accounts,
    sync_account
)


class TestSync:
    """Test cases for sync functionality"""

    def test_sync_skip_when_not_connected(self, qonto_settings):
        """Test sync skips when not connected"""
        qonto_settings.connected = False
        qonto_settings.save()
        
        # Should not raise error, just skip
        schedule_all_syncs()

    def test_sync_skip_when_already_running(self, qonto_settings):
        """Test sync skips when already running"""
        qonto_settings.connected = True
        qonto_settings.save()
        
        # Set sync lock
        frappe.cache().set_value("qonto_sync_running", True)
        
        try:
            # Should not raise error, just skip
            schedule_all_syncs()
        finally:
            # Cleanup
            frappe.cache().delete_value("qonto_sync_running")

    @patch("qonto_connector.qonto.sync.sync_all_accounts")
    def test_sync_sets_lock(self, mock_sync_all, qonto_settings):
        """Test sync sets and releases lock"""
        qonto_settings.connected = True
        qonto_settings.save()
        
        schedule_all_syncs()
        
        # Lock should be released after sync
        assert not frappe.cache().get_value("qonto_sync_running")

    def test_sync_no_active_mappings(self, qonto_settings, mock_qonto_client):
        """Test sync with no active mappings"""
        qonto_settings.connected = True
        qonto_settings.account_mappings = []
        
        with patch("qonto_connector.qonto.client.QontoClient", return_value=mock_qonto_client):
            sync_all_accounts(qonto_settings)
        
        # Should complete without error
        assert qonto_settings.last_sync_at

    def test_sync_account_first_time(self, qonto_settings, mock_qonto_client, sample_transaction):
        """Test syncing account for first time"""
        # Create mock mapping
        mapping = Mock()
        mapping.qonto_bank_account_id = "test-account-001"
        mapping.last_synced_at = None
        mapping.active = True
        
        # Mock transaction iterator
        mock_qonto_client.iter_transactions.return_value = iter([
            {
                "qonto_id": "tx-001",
                "posting_date": "2025-10-04",
                "amount": -50.00,
                "currency": "EUR",
                "description": "Test",
                "raw_data": sample_transaction
            }
        ])
        
        with patch("qonto_connector.qonto.mapping.upsert_bank_transaction"):
            count = sync_account(mock_qonto_client, mapping, 90)
        
        # Should have synced one transaction
        assert count == 1


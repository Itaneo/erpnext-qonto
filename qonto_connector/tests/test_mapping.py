# Copyright (c) 2025, Itanéo and Contributors
# See license.txt

"""Tests for account mapping and transaction creation"""

import pytest
import frappe
from unittest.mock import Mock, patch
from qonto_connector.qonto.mapping import (
    upsert_bank_transaction,
    create_bank_transaction_from_qonto
)


class TestMapping:
    """Test cases for mapping functionality"""

    @pytest.fixture
    def test_company(self):
        """Create test company"""
        if not frappe.db.exists("Company", "Test Company"):
            company = frappe.get_doc({
                "doctype": "Company",
                "company_name": "Test Company",
                "abbr": "TC",
                "default_currency": "EUR"
            })
            company.insert(ignore_permissions=True)
            frappe.db.commit()
        
        yield "Test Company"

    @pytest.fixture
    def test_bank_account(self, test_company):
        """Create test bank account"""
        if not frappe.db.exists("Bank Account", "Test Bank Account - TC"):
            bank_account = frappe.get_doc({
                "doctype": "Bank Account",
                "account_name": "Test Bank Account",
                "bank": "Test Bank",
                "company": test_company,
                "account_currency": "EUR"
            })
            bank_account.insert(ignore_permissions=True)
            frappe.db.commit()
        
        yield "Test Bank Account - TC"

    def test_create_bank_transaction(self, test_company, test_bank_account, sample_transaction):
        """Test creating bank transaction from Qonto data"""
        tx_data = {
            "qonto_id": "test-tx-001",
            "posting_date": "2025-10-04",
            "amount": -50.00,
            "currency": "EUR",
            "description": "Test Transaction",
            "raw_data": sample_transaction
        }
        
        with patch("qonto_connector.qonto.mapping.frappe.new_doc") as mock_new_doc:
            mock_doc = Mock()
            mock_new_doc.return_value = mock_doc
            
            create_bank_transaction_from_qonto(
                test_company,
                test_bank_account,
                tx_data
            )
            
            # Verify doc was created and saved
            assert mock_doc.insert.called

    def test_upsert_existing_transaction(self, sample_transaction):
        """Test upserting existing transaction"""
        # Mock existing transaction
        with patch("frappe.db.get_value") as mock_get_value:
            mock_get_value.return_value = {
                "name": "BANK-TX-001",
                "docstatus": 1  # Submitted
            }
            
            mapping = Mock()
            mapping.company = "Test Company"
            mapping.erpnext_bank_account = "Test Bank Account"
            
            tx_data = {
                "qonto_id": "test-tx-001",
                "posting_date": "2025-10-04",
                "amount": -50.00,
                "currency": "EUR",
                "description": "Test",
                "raw_data": sample_transaction
            }
            
            # Should skip submitted transaction
            upsert_bank_transaction(mapping, tx_data)


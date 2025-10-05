# Copyright (c) 2025, Itanéo and Contributors
# See license.txt

import frappe
from frappe.tests.utils import FrappeTestCase


class TestQontoSettings(FrappeTestCase):
    """Test cases for Qonto Settings"""

    def setUp(self):
        """Set up test data"""
        # Clear any existing settings
        if frappe.db.exists("Qonto Settings", "Qonto Settings"):
            doc = frappe.get_doc("Qonto Settings", "Qonto Settings")
            doc.delete()

    def test_settings_creation(self):
        """Test creating Qonto Settings"""
        doc = frappe.get_doc({
            "doctype": "Qonto Settings",
            "environment": "Sandbox",
            "api_login": "test-org",
            "api_secret_key": "test-key",
            "poll_interval_minutes": 15,
            "default_sync_lookback_days": 90
        })
        doc.insert()
        self.assertTrue(doc.name)

    def test_poll_interval_validation(self):
        """Test poll interval validation"""
        doc = frappe.get_doc({
            "doctype": "Qonto Settings",
            "environment": "Sandbox",
            "api_login": "test-org",
            "api_secret_key": "test-key",
            "poll_interval_minutes": 3,  # Too low
            "default_sync_lookback_days": 90
        })
        with self.assertRaises(frappe.ValidationError):
            doc.insert()

    def test_lookback_days_validation(self):
        """Test lookback days validation"""
        doc = frappe.get_doc({
            "doctype": "Qonto Settings",
            "environment": "Sandbox",
            "api_login": "test-org",
            "api_secret_key": "test-key",
            "poll_interval_minutes": 15,
            "default_sync_lookback_days": 0  # Too low
        })
        with self.assertRaises(frappe.ValidationError):
            doc.insert()

    def tearDown(self):
        """Clean up test data"""
        if frappe.db.exists("Qonto Settings", "Qonto Settings"):
            doc = frappe.get_doc("Qonto Settings", "Qonto Settings")
            doc.delete()


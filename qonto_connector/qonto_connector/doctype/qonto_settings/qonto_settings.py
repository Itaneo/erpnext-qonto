# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

import frappe
from frappe import _
from frappe.model.document import Document


class QontoSettings(Document):
    """Qonto Settings DocType"""

    def validate(self):
        """Validate settings before save"""
        # Validate poll interval
        if self.poll_interval_minutes and self.poll_interval_minutes < 5:
            frappe.throw(_("Sync interval must be at least 5 minutes"))

        # Validate lookback days
        if self.default_sync_lookback_days and self.default_sync_lookback_days < 1:
            frappe.throw(_("Default lookback days must be at least 1 day"))

    def on_update(self):
        """Called after document is saved"""
        # Clear cache on settings update
        frappe.cache().delete_value("qonto_settings")


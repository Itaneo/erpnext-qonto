# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Utility functions for Qonto Connector"""

import json
import frappe
from frappe import _
from frappe.utils import now_datetime
from typing import Dict, Any, Optional

from .constants import (
    CUSTOM_FIELD_QONTO_ID,
    CUSTOM_FIELD_QONTO_DATA,
    ROLE_QONTO_MANAGER,
)


def log_sync(
    level: str,
    message: str,
    context: Optional[Dict[str, Any]] = None,
    duration_ms: Optional[int] = None,
    items_processed: Optional[int] = None
):
    """
    Log sync operation.

    Args:
        level: Log level (INFO, WARN, ERROR)
        message: Log message
        context: Additional context data
        duration_ms: Duration in milliseconds
        items_processed: Number of items processed
    """
    try:
        doc = frappe.get_doc({
            "doctype": "Qonto Sync Log",
            "run_at": now_datetime(),
            "level": level,
            "message": message,
            "context_json": json.dumps(context) if context else None,
            "duration_ms": duration_ms,
            "items_processed": items_processed
        })
        doc.insert(ignore_permissions=True)
        frappe.db.commit()
    except Exception as e:
        frappe.log_error(f"Failed to create sync log: {str(e)}", "Qonto Sync Log")


def ensure_custom_fields():
    """
    Ensure custom fields exist on Bank Transaction doctype.
    Called after migration.
    """
    # Check if custom fields already exist
    if frappe.db.exists("Custom Field", {"dt": "Bank Transaction", "fieldname": CUSTOM_FIELD_QONTO_ID}):
        return

    # Create Qonto ID field
    frappe.get_doc({
        "doctype": "Custom Field",
        "dt": "Bank Transaction",
        "fieldname": CUSTOM_FIELD_QONTO_ID,
        "label": "Qonto Transaction ID",
        "fieldtype": "Data",
        "insert_after": "description",
        "read_only": 1,
        "unique": 1,
        "hidden": 0,
        "allow_on_submit": 0,
        "description": "Unique transaction ID from Qonto"
    }).insert(ignore_permissions=True)

    # Create Qonto Data field
    frappe.get_doc({
        "doctype": "Custom Field",
        "dt": "Bank Transaction",
        "fieldname": CUSTOM_FIELD_QONTO_DATA,
        "label": "Qonto Data",
        "fieldtype": "Long Text",
        "insert_after": CUSTOM_FIELD_QONTO_ID,
        "read_only": 1,
        "hidden": 1,
        "allow_on_submit": 0,
        "description": "Raw transaction data from Qonto API"
    }).insert(ignore_permissions=True)

    frappe.db.commit()


def ensure_qonto_manager_role():
    """
    Ensure Qonto Manager role exists.
    Called after migration.
    """
    if frappe.db.exists("Role", ROLE_QONTO_MANAGER):
        return

    role = frappe.get_doc({
        "doctype": "Role",
        "role_name": ROLE_QONTO_MANAGER,
        "desk_access": 1,
        "search_bar": 1,
        "notifications": 1,
    })
    role.insert(ignore_permissions=True)
    frappe.db.commit()


def prevent_duplicate_qonto_transaction(doc, method=None):
    """
    Prevent duplicate Qonto transactions.
    Hook for Bank Transaction before_insert.

    Args:
        doc: Bank Transaction document
        method: Hook method name
    """
    if not doc.get(CUSTOM_FIELD_QONTO_ID):
        return

    # Check if transaction already exists
    existing = frappe.db.get_value(
        "Bank Transaction",
        {CUSTOM_FIELD_QONTO_ID: doc.get(CUSTOM_FIELD_QONTO_ID)},
        "name"
    )

    if existing:
        frappe.throw(
            _("Qonto transaction {0} already exists as {1}").format(
                doc.get(CUSTOM_FIELD_QONTO_ID),
                existing
            )
        )


def get_qonto_settings():
    """
    Get Qonto Settings with caching.

    Returns:
        QontoSettings document
    """
    # Try to get from cache
    cached = frappe.cache().get_value("qonto_settings")
    if cached:
        return frappe.get_doc("Qonto Settings", "Qonto Settings")

    # Get from database and cache
    settings = frappe.get_doc("Qonto Settings", "Qonto Settings")
    frappe.cache().set_value("qonto_settings", True, expires_in_sec=300)  # Cache for 5 minutes
    return settings


def validate_bank_account_mapping(mapping: Dict[str, Any]):
    """
    Validate bank account mapping configuration.

    Args:
        mapping: Account mapping dictionary

    Raises:
        frappe.ValidationError: If validation fails
    """
    # Check if ERPNext bank account exists
    if not frappe.db.exists("Bank Account", mapping.get("erpnext_bank_account")):
        frappe.throw(_("Bank Account {0} does not exist").format(
            mapping.get("erpnext_bank_account")
        ))

    # Check if company exists
    if not frappe.db.exists("Company", mapping.get("company")):
        frappe.throw(_("Company {0} does not exist").format(mapping.get("company")))

    # Check if bank account belongs to company
    bank_account = frappe.get_doc("Bank Account", mapping.get("erpnext_bank_account"))
    if bank_account.company != mapping.get("company"):
        frappe.throw(_(
            "Bank Account {0} does not belong to Company {1}"
        ).format(mapping.get("erpnext_bank_account"), mapping.get("company")))


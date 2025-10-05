# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""REST API endpoints for Qonto Connector."""

import frappe
from frappe import _

from qonto_connector.qonto.client import QontoClient
from qonto_connector.qonto.utils import log_sync
from qonto_connector.qonto.constants import CACHE_KEY_SYNC_RUNNING


@frappe.whitelist()
def test_connection():
    """
    Test Qonto API connection.

    Returns:
        dict: Success status and message
    """
    frappe.only_for("System Manager", "Qonto Manager")

    try:
        settings = frappe.get_single("Qonto Settings")
        client = QontoClient(settings)

        # Test connection and get organization info
        org_data = client.get_organization()

        # Update settings
        settings.organization_id = org_data.get("slug")
        settings.organization_name = org_data.get("name") or org_data.get("legal_name")
        settings.connected = True
        settings.last_error = None
        settings.save(ignore_permissions=True)

        return {
            "success": True,
            "message": _("Connection successful!"),
            "organization": {
                "id": org_data.get("slug"),
                "name": org_data.get("name") or org_data.get("legal_name"),
                "bank_accounts": len(org_data.get("bank_accounts", []))
            }
        }

    except Exception as e:
        settings = frappe.get_single("Qonto Settings")
        settings.connected = False
        settings.last_error = str(e)
        settings.save(ignore_permissions=True)

        frappe.log_error(f"Qonto connection test failed: {str(e)}", "Qonto Connection")
        return {
            "success": False,
            "message": str(e)
        }


@frappe.whitelist()
def fetch_accounts():
    """
    Fetch available Qonto bank accounts.

    Returns:
        dict: Success status and list of accounts
    """
    frappe.only_for("System Manager", "Qonto Manager")

    try:
        settings = frappe.get_single("Qonto Settings")

        if not settings.connected:
            return {
                "success": False,
                "message": _("Please test connection first")
            }

        client = QontoClient(settings)
        accounts = client.list_accounts()

        # Format for frontend
        formatted_accounts = []
        for acc in accounts:
            formatted_accounts.append({
                "id": acc.get("slug"),
                "name": acc.get("name"),
                "iban": acc.get("iban"),
                "bic": acc.get("bic"),
                "currency": acc.get("currency"),
                "balance": acc.get("balance"),
                "balance_cents": acc.get("balance_cents"),
                "status": acc.get("status")
            })

        return {
            "success": True,
            "accounts": formatted_accounts
        }

    except Exception as e:
        frappe.log_error(f"Failed to fetch Qonto accounts: {str(e)}", "Qonto Fetch")
        return {
            "success": False,
            "message": str(e)
        }


@frappe.whitelist()
def sync_now():
    """
    Trigger immediate sync.

    Returns:
        dict: Success status and message
    """
    frappe.only_for("System Manager", "Qonto Manager")

    # Check if sync is already running
    if frappe.cache().get_value(CACHE_KEY_SYNC_RUNNING):
        return {
            "success": False,
            "message": _("Sync is already in progress")
        }

    # Enqueue sync job
    frappe.enqueue(
        "qonto_connector.qonto.sync.schedule_all_syncs",
        queue="long",
        timeout=900,
        job_name="qonto_sync_manual"
    )

    log_sync("INFO", "Manual sync triggered")

    return {
        "success": True,
        "message": _("Sync has been queued and will start shortly")
    }


@frappe.whitelist()
def get_sync_status():
    """
    Get current sync status.

    Returns:
        dict: Current sync status and recent logs
    """
    frappe.only_for("System Manager", "Qonto Manager")

    settings = frappe.get_single("Qonto Settings")
    is_running = bool(frappe.cache().get_value(CACHE_KEY_SYNC_RUNNING))

    # Get recent logs
    logs = frappe.get_all(
        "Qonto Sync Log",
        fields=["run_at", "level", "message", "items_processed", "duration_ms"],
        order_by="creation desc",
        limit=10
    )

    return {
        "connected": settings.connected,
        "is_running": is_running,
        "last_sync": settings.last_sync_at,
        "last_error": settings.last_error,
        "recent_logs": logs,
        "active_mappings": len([m for m in settings.account_mappings if m.active])
    }


@frappe.whitelist()
def get_account_sync_summary():
    """
    Get sync summary for each account mapping.

    Returns:
        dict: Sync summary data
    """
    frappe.only_for("System Manager", "Qonto Manager")

    settings = frappe.get_single("Qonto Settings")
    summaries = []

    for mapping in settings.account_mappings:
        # Count transactions for this account
        transaction_count = frappe.db.count(
            "Bank Transaction",
            filters={
                "bank_account": mapping.erpnext_bank_account,
                "company": mapping.company
            }
        )

        summaries.append({
            "qonto_account_id": mapping.qonto_bank_account_id,
            "iban": mapping.iban,
            "qonto_name": mapping.qonto_name,
            "erpnext_bank_account": mapping.erpnext_bank_account,
            "company": mapping.company,
            "active": mapping.active,
            "last_synced_at": mapping.last_synced_at,
            "transaction_count": transaction_count
        })

    return {
        "success": True,
        "summaries": summaries
    }


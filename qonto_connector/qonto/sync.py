# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Transaction sync engine."""

import frappe
from frappe.utils import now_datetime, get_datetime, add_days

from .client import QontoClient
from .mapping import upsert_bank_transaction
from .utils import log_sync
from .constants import CACHE_KEY_SYNC_RUNNING, SYNC_LOCK_TIMEOUT


def schedule_all_syncs():
    """
    Scheduled task to sync all active account mappings.
    Called by scheduler every 15 minutes.
    """
    try:
        settings = frappe.get_single("Qonto Settings")

        if not settings.connected:
            log_sync("WARN", "Qonto not connected. Skipping sync.")
            return

        # Check if sync is already running
        if frappe.cache().get_value(CACHE_KEY_SYNC_RUNNING):
            log_sync("INFO", "Sync already in progress. Skipping.")
            return

        # Set sync lock
        frappe.cache().set_value(
            CACHE_KEY_SYNC_RUNNING,
            True,
            expires_in_sec=SYNC_LOCK_TIMEOUT
        )

        try:
            sync_all_accounts(settings)
        finally:
            frappe.cache().delete_value(CACHE_KEY_SYNC_RUNNING)

    except Exception as e:
        log_sync("ERROR", f"Sync scheduler error: {str(e)}", {"error": str(e)})
        frappe.log_error(f"Qonto sync scheduler error: {str(e)}", "Qonto Sync")
        raise


def sync_all_accounts(settings):
    """
    Sync all active account mappings.

    Args:
        settings: QontoSettings document
    """
    client = QontoClient(settings)

    active_mappings = [m for m in settings.account_mappings if m.active]

    if not active_mappings:
        log_sync("INFO", "No active account mappings found.")
        return

    total_synced = 0
    errors = []
    start_time = frappe.utils.now()

    for mapping in active_mappings:
        try:
            count = sync_account(
                client,
                mapping,
                settings.default_sync_lookback_days
            )
            total_synced += count

            # Update mapping
            mapping.last_synced_at = now_datetime()
            # Note: We don't save here to avoid nested saves

        except Exception as e:
            error_msg = f"Error syncing {mapping.qonto_bank_account_id}: {str(e)}"
            errors.append(error_msg)
            log_sync(
                "ERROR",
                error_msg,
                {"account_id": mapping.qonto_bank_account_id, "error": str(e)}
            )
            frappe.log_error(error_msg, "Qonto Account Sync")

    # Update settings
    settings.last_sync_at = now_datetime()
    if errors:
        settings.last_error = "\n".join(errors[-5:])  # Keep last 5 errors
    else:
        settings.last_error = None

    settings.save(ignore_permissions=True)
    frappe.db.commit()

    # Calculate duration
    end_time = frappe.utils.now()
    duration_ms = int(
        (get_datetime(end_time) - get_datetime(start_time)).total_seconds() * 1000
    )

    log_sync(
        "INFO",
        f"Sync completed. {total_synced} transactions synced.",
        {
            "total": total_synced,
            "errors": len(errors),
            "mappings": len(active_mappings)
        },
        duration_ms=duration_ms,
        items_processed=total_synced
    )


def sync_account(
    client: QontoClient,
    mapping,
    default_lookback_days: int
) -> int:
    """
    Sync transactions for a single account mapping.

    Args:
        client: QontoClient instance
        mapping: QontoAccountMapping document
        default_lookback_days: Default number of days to look back

    Returns:
        Number of transactions synced
    """
    # Determine sync start date
    if mapping.last_synced_at:
        sync_from = get_datetime(mapping.last_synced_at).isoformat()
    else:
        sync_from = add_days(now_datetime(), -default_lookback_days).isoformat()

    count = 0

    # Fetch and process transactions
    for tx_data in client.iter_transactions(
        mapping.qonto_bank_account_id,
        updated_at_from=sync_from,
        status=["settled"]  # Only sync settled transactions
    ):
        try:
            upsert_bank_transaction(mapping, tx_data)
            count += 1

            # Commit every 50 transactions
            if count % 50 == 0:
                frappe.db.commit()

        except Exception as e:
            error_msg = f"Error processing transaction {tx_data.get('qonto_id')}: {str(e)}"
            log_sync(
                "ERROR",
                error_msg,
                {"transaction": tx_data, "error": str(e)}
            )
            frappe.log_error(error_msg, "Qonto Transaction Sync")
            # Continue with next transaction

    frappe.db.commit()
    return count


def sync_single_account_now(qonto_bank_account_id: str):
    """
    Sync a single account immediately (for manual trigger).

    Args:
        qonto_bank_account_id: Qonto bank account ID to sync
    """
    settings = frappe.get_single("Qonto Settings")

    if not settings.connected:
        frappe.throw("Qonto is not connected. Please test connection first.")

    # Find the mapping
    mapping = None
    for m in settings.account_mappings:
        if m.qonto_bank_account_id == qonto_bank_account_id and m.active:
            mapping = m
            break

    if not mapping:
        frappe.throw(f"No active mapping found for account {qonto_bank_account_id}")

    # Sync the account
    client = QontoClient(settings)
    count = sync_account(client, mapping, settings.default_sync_lookback_days)

    # Update mapping and settings
    mapping.last_synced_at = now_datetime()
    settings.last_sync_at = now_datetime()
    settings.save(ignore_permissions=True)
    frappe.db.commit()

    return count


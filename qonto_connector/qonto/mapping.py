# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Account mapping and transaction creation logic."""

import json
import frappe
from frappe.utils import flt
from typing import Dict, Any

from .constants import CUSTOM_FIELD_QONTO_ID, CUSTOM_FIELD_QONTO_DATA


def upsert_bank_transaction(mapping, tx_data: Dict[str, Any]):
    """
    Create or update bank transaction from Qonto data.

    Args:
        mapping: QontoAccountMapping document
        tx_data: Normalized transaction data from Qonto API
    """
    qonto_id = tx_data["qonto_id"]

    # Check if transaction already exists
    existing = frappe.db.get_value(
        "Bank Transaction",
        {CUSTOM_FIELD_QONTO_ID: qonto_id},
        ["name", "docstatus"],
        as_dict=True
    )

    if existing:
        # Skip if already submitted
        if existing.docstatus == 1:
            return

        # Update existing draft
        doc = frappe.get_doc("Bank Transaction", existing.name)
    else:
        # Create new
        doc = frappe.new_doc("Bank Transaction")
        setattr(doc, CUSTOM_FIELD_QONTO_ID, qonto_id)

    # Get bank account details
    bank_account = frappe.get_doc("Bank Account", mapping.erpnext_bank_account)

    # Update fields
    doc.update({
        "date": tx_data["posting_date"],
        "bank_account": mapping.erpnext_bank_account,
        "company": mapping.company,
        "description": tx_data["description"],
        "currency": bank_account.account_currency or tx_data["currency"],
    })

    # Set Qonto data
    setattr(doc, CUSTOM_FIELD_QONTO_DATA, json.dumps(tx_data["raw_data"], indent=2))

    # Set debit or credit based on amount
    amount = abs(flt(tx_data["amount"]))
    if tx_data["amount"] < 0:
        doc.withdrawal = amount
        doc.deposit = 0
    else:
        doc.deposit = amount
        doc.withdrawal = 0

    # Save
    doc.save(ignore_permissions=True)

    # Auto-submit if configured (future feature)
    # if settings.auto_submit_transactions:
    #     doc.submit()


def create_bank_transaction_from_qonto(
    company: str,
    bank_account: str,
    tx_data: Dict[str, Any]
) -> str:
    """
    Create a new bank transaction from Qonto data.

    Args:
        company: Company name
        bank_account: ERPNext Bank Account name
        tx_data: Normalized transaction data

    Returns:
        Name of created Bank Transaction
    """
    doc = frappe.new_doc("Bank Transaction")

    # Set Qonto ID
    setattr(doc, CUSTOM_FIELD_QONTO_ID, tx_data["qonto_id"])

    # Get bank account details
    bank_account_doc = frappe.get_doc("Bank Account", bank_account)

    # Set basic fields
    doc.date = tx_data["posting_date"]
    doc.bank_account = bank_account
    doc.company = company
    doc.description = tx_data["description"]
    doc.currency = bank_account_doc.account_currency or tx_data["currency"]

    # Set Qonto data
    setattr(doc, CUSTOM_FIELD_QONTO_DATA, json.dumps(tx_data["raw_data"], indent=2))

    # Set debit or credit based on amount
    amount = abs(flt(tx_data["amount"]))
    if tx_data["amount"] < 0:
        doc.withdrawal = amount
        doc.deposit = 0
    else:
        doc.deposit = amount
        doc.withdrawal = 0

    # Save and return
    doc.insert(ignore_permissions=True)
    return doc.name


def update_bank_transaction_from_qonto(
    transaction_name: str,
    tx_data: Dict[str, Any]
):
    """
    Update existing bank transaction from Qonto data.

    Args:
        transaction_name: Name of Bank Transaction to update
        tx_data: Normalized transaction data
    """
    doc = frappe.get_doc("Bank Transaction", transaction_name)

    # Don't update if submitted
    if doc.docstatus == 1:
        return

    # Update fields
    doc.date = tx_data["posting_date"]
    doc.description = tx_data["description"]

    # Update Qonto data
    setattr(doc, CUSTOM_FIELD_QONTO_DATA, json.dumps(tx_data["raw_data"], indent=2))

    # Update amounts
    amount = abs(flt(tx_data["amount"]))
    if tx_data["amount"] < 0:
        doc.withdrawal = amount
        doc.deposit = 0
    else:
        doc.deposit = amount
        doc.withdrawal = 0

    # Save
    doc.save(ignore_permissions=True)


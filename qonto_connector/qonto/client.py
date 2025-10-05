# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Qonto API Client with retry logic and error handling."""

import time
from typing import Dict, Any, Optional, Iterator, List
from urllib.parse import urljoin
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import frappe

from .exceptions import QontoAPIError, QontoAuthError, QontoRateLimitError
from .constants import (
    QONTO_PRODUCTION_URL,
    QONTO_SANDBOX_URL,
    ENDPOINTS,
    DEFAULT_PAGE_SIZE,
    MAX_RETRIES,
    BACKOFF_FACTOR,
)


class QontoClient:
    """Thread-safe Qonto API client with automatic retry and rate limiting."""

    def __init__(self, settings):
        """
        Initialize Qonto API client.

        Args:
            settings: QontoSettings document
        """
        self.settings = settings
        self.base_url = self._get_base_url()
        self.session = self._create_session()

    def _get_base_url(self) -> str:
        """Get API base URL based on environment."""
        if self.settings.environment == "Production":
            return QONTO_PRODUCTION_URL
        return QONTO_SANDBOX_URL

    def _create_session(self) -> requests.Session:
        """Create requests session with retry strategy."""
        session = requests.Session()

        # Retry strategy
        retry_strategy = Retry(
            total=MAX_RETRIES,
            backoff_factor=BACKOFF_FACTOR,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["GET", "POST", "PUT", "DELETE"]
        )

        adapter = HTTPAdapter(max_retries=retry_strategy)
        session.mount("http://", adapter)
        session.mount("https://", adapter)

        # Set headers
        api_secret = self.settings.get_password("api_secret_key")
        session.headers.update({
            "Authorization": f"{self.settings.api_login}:{api_secret}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": f"ERPNext-Qonto-Connector/{frappe.get_installed_app_version('qonto_connector')}"
        })

        return session

    def _request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        """
        Make API request with error handling.

        Args:
            method: HTTP method
            endpoint: API endpoint
            **kwargs: Additional request parameters

        Returns:
            Response JSON data

        Raises:
            QontoAuthError: When authentication fails
            QontoRateLimitError: When rate limit is exceeded
            QontoAPIError: For other API errors
        """
        url = urljoin(self.base_url, endpoint)

        try:
            response = self.session.request(method, url, **kwargs)

            if response.status_code == 401:
                raise QontoAuthError("Invalid API credentials")
            elif response.status_code == 429:
                retry_after = int(response.headers.get("Retry-After", 60))
                raise QontoRateLimitError(
                    f"Rate limit exceeded. Retry after {retry_after}s",
                    retry_after
                )

            response.raise_for_status()
            return response.json()

        except requests.exceptions.RequestException as e:
            frappe.log_error(f"Qonto API Error: {str(e)}", "Qonto API")
            raise QontoAPIError(f"API request failed: {str(e)}") from e

    def test_connection(self) -> Dict[str, Any]:
        """
        Test API connection and get organization info.

        Returns:
            Organization data
        """
        return self._request("GET", ENDPOINTS["organization"])

    def get_organization(self) -> Dict[str, Any]:
        """
        Get organization details including bank accounts.

        Returns:
            Organization data
        """
        data = self._request("GET", ENDPOINTS["organization"])
        return data.get("organization", {})

    def list_accounts(self) -> List[Dict[str, Any]]:
        """
        List all bank accounts.

        Returns:
            List of bank account dictionaries
        """
        org = self.get_organization()
        return org.get("bank_accounts", [])

    def iter_transactions(
        self,
        bank_account_id: str,
        updated_at_from: Optional[str] = None,
        status: Optional[List[str]] = None,
        page_size: int = DEFAULT_PAGE_SIZE
    ) -> Iterator[Dict[str, Any]]:
        """
        Iterate through transactions with automatic pagination.

        Args:
            bank_account_id: Qonto bank account ID
            updated_at_from: ISO datetime to fetch transactions updated after
            status: List of transaction statuses to filter
            page_size: Number of transactions per page

        Yields:
            Normalized transaction dictionaries
        """
        params = {
            "bank_account_id": bank_account_id,
            "per_page": page_size,
            "page": 1
        }

        if updated_at_from:
            params["updated_at_from"] = updated_at_from

        if status:
            params["status[]"] = status

        while True:
            try:
                data = self._request("GET", ENDPOINTS["transactions"], params=params)
                transactions = data.get("transactions", [])

                if not transactions:
                    break

                for transaction in transactions:
                    yield self._normalize_transaction(transaction)

                # Check for next page
                meta = data.get("meta", {})
                if params["page"] >= meta.get("total_pages", 1):
                    break

                params["page"] += 1

            except QontoRateLimitError as e:
                frappe.log_error(f"Rate limit hit: {str(e)}", "Qonto Sync")
                time.sleep(e.retry_after)
                continue

    def _normalize_transaction(self, tx: Dict[str, Any]) -> Dict[str, Any]:
        """
        Normalize transaction data for ERPNext.

        Args:
            tx: Raw transaction data from Qonto API

        Returns:
            Normalized transaction dictionary
        """
        # Determine posting date
        posting_date = tx.get("settled_at") or tx.get("emitted_at")

        # Calculate signed amount
        amount = float(tx.get("amount", 0))
        if tx.get("side") == "debit":
            amount = -amount

        # Build description
        parts = []
        if tx.get("label"):
            parts.append(tx["label"])
        if tx.get("reference"):
            parts.append(tx["reference"])
        if tx.get("counterparty_name"):
            parts.append(tx["counterparty_name"])

        description = " — ".join(parts) or "Qonto Transaction"

        return {
            "qonto_id": tx["transaction_id"],
            "posting_date": posting_date,
            "amount": amount,
            "currency": tx.get("currency", "EUR"),
            "description": description,
            "status": tx.get("status"),
            "side": tx.get("side"),
            "operation_type": tx.get("operation_type"),
            "attachment_ids": tx.get("attachment_ids", []),
            "raw_data": tx  # Keep original for reference
        }


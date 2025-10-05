# Copyright (c) 2025, Itanéo and Contributors
# See license.txt

"""Tests for Qonto API client"""

import pytest
import frappe
from unittest.mock import Mock, patch, MagicMock
from qonto_connector.qonto.client import QontoClient
from qonto_connector.qonto.exceptions import (
    QontoAuthError,
    QontoRateLimitError,
    QontoAPIError
)


class TestQontoClient:
    """Test cases for QontoClient"""

    def test_client_initialization(self, qonto_settings):
        """Test client initialization"""
        client = QontoClient(qonto_settings)
        assert client.settings == qonto_settings
        assert client.base_url
        assert client.session

    def test_base_url_sandbox(self, qonto_settings):
        """Test sandbox base URL"""
        qonto_settings.environment = "Sandbox"
        client = QontoClient(qonto_settings)
        assert "sandbox" in client.base_url.lower()

    def test_base_url_production(self, qonto_settings):
        """Test production base URL"""
        qonto_settings.environment = "Production"
        client = QontoClient(qonto_settings)
        assert "sandbox" not in client.base_url.lower()

    @patch("requests.Session.request")
    def test_auth_error(self, mock_request, qonto_settings):
        """Test authentication error handling"""
        mock_response = Mock()
        mock_response.status_code = 401
        mock_request.return_value = mock_response

        client = QontoClient(qonto_settings)
        
        with pytest.raises(QontoAuthError):
            client._request("GET", "organization")

    @patch("requests.Session.request")
    def test_rate_limit_error(self, mock_request, qonto_settings):
        """Test rate limit error handling"""
        mock_response = Mock()
        mock_response.status_code = 429
        mock_response.headers = {"Retry-After": "60"}
        mock_request.return_value = mock_response

        client = QontoClient(qonto_settings)
        
        with pytest.raises(QontoRateLimitError) as exc_info:
            client._request("GET", "organization")
        
        assert exc_info.value.retry_after == 60

    @patch("requests.Session.request")
    def test_successful_request(self, mock_request, qonto_settings):
        """Test successful API request"""
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"organization": {"name": "Test"}}
        mock_request.return_value = mock_response

        client = QontoClient(qonto_settings)
        result = client._request("GET", "organization")
        
        assert result == {"organization": {"name": "Test"}}

    def test_normalize_transaction(self, qonto_settings, sample_transaction):
        """Test transaction normalization"""
        client = QontoClient(qonto_settings)
        normalized = client._normalize_transaction(sample_transaction)
        
        assert normalized["qonto_id"] == sample_transaction["transaction_id"]
        assert normalized["amount"] < 0  # Debit should be negative
        assert normalized["currency"] == "EUR"
        assert "description" in normalized


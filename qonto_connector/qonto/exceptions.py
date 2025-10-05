# Copyright (c) 2025, Itanéo and contributors
# For license information, please see license.txt

"""Custom exceptions for Qonto Connector"""


class QontoError(Exception):
    """Base exception for Qonto errors"""
    pass


class QontoAPIError(QontoError):
    """Raised when API request fails"""
    pass


class QontoAuthError(QontoAPIError):
    """Raised when authentication fails"""
    pass


class QontoRateLimitError(QontoAPIError):
    """Raised when rate limit is exceeded"""
    
    def __init__(self, message: str, retry_after: int = 60):
        super().__init__(message)
        self.retry_after = retry_after


class QontoSyncError(QontoError):
    """Raised when sync operation fails"""
    pass


class QontoMappingError(QontoError):
    """Raised when account mapping is invalid"""
    pass


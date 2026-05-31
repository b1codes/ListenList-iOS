import pytest
from unittest.mock import patch


@pytest.fixture(autouse=True)
def mock_auth0_settings():
    """Provide a valid AUTH0_DOMAIN so URL construction works in tests."""
    with patch("app.auth.auth0.settings") as mock_settings:
        mock_settings.AUTH0_DOMAIN = "test.auth0.com"
        mock_settings.AUTH0_CLIENT_ID = "test-client-id"
        yield mock_settings

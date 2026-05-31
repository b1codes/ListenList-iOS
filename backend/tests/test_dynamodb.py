from unittest.mock import MagicMock
from app.services.dynamodb import DynamoDBService


def _make_service(table: MagicMock) -> DynamoDBService:
    """Bypass __init__ (which connects to DynamoDB) and inject a mock table."""
    service = DynamoDBService.__new__(DynamoDBService)
    service.table = table
    return service


def test_create_or_update_user_stores_provider_fields():
    mock_table = MagicMock()
    mock_table.update_item.return_value = {}
    mock_table.get_item.return_value = {
        "Item": {
            "PK": "USER#abc",
            "SK": "PROFILE",
            "provider_sub": "auth0|sub123",
            "auth_provider": "auth0",
        }
    }
    service = _make_service(mock_table)

    service.create_or_update_user(
        user_id="abc",
        provider_sub="auth0|sub123",
        auth_provider="auth0",
        email="user@example.com",
    )

    call_kwargs = mock_table.update_item.call_args.kwargs
    attrs = call_kwargs["ExpressionAttributeValues"]
    assert attrs[":provider_sub"] == "auth0|sub123"
    assert attrs[":auth_provider"] == "auth0"
    assert attrs[":entity_type"] == "user"


def test_create_or_update_user_apple_provider():
    mock_table = MagicMock()
    mock_table.update_item.return_value = {}
    mock_table.get_item.return_value = {"Item": {}}
    service = _make_service(mock_table)

    service.create_or_update_user(
        user_id="xyz",
        provider_sub="appleSub.123",
        auth_provider="apple",
        email="apple@example.com",
        name="Apple User",
    )

    call_kwargs = mock_table.update_item.call_args.kwargs
    attrs = call_kwargs["ExpressionAttributeValues"]
    assert attrs[":auth_provider"] == "apple"
    assert attrs[":provider_sub"] == "appleSub.123"
    assert attrs[":email"] == "apple@example.com"
    assert attrs[":name"] == "Apple User"


def test_create_or_update_user_optional_fields_omitted():
    mock_table = MagicMock()
    mock_table.update_item.return_value = {}
    mock_table.get_item.return_value = {"Item": {}}
    service = _make_service(mock_table)

    service.create_or_update_user(
        user_id="u1",
        provider_sub="sub1",
        auth_provider="auth0",
    )

    call_kwargs = mock_table.update_item.call_args.kwargs
    attrs = call_kwargs["ExpressionAttributeValues"]
    assert ":email" not in attrs
    assert ":name" not in attrs

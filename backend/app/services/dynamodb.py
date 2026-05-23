import boto3
import time
from botocore.exceptions import ClientError
from fastapi import HTTPException, status
from app.config import settings
from typing import List, Dict, Any, Optional

class DynamoDBService:
    def __init__(self):
        # Allow connecting to local DynamoDB when working locally
        if settings.ENV == "local":
            self.dynamodb = boto3.resource(
                "dynamodb",
                region_name=settings.AWS_REGION,
                endpoint_url="http://localhost:8000"
            )
        else:
            self.dynamodb = boto3.resource("dynamodb", region_name=settings.AWS_REGION)
        
        self.table = self.dynamodb.Table(settings.DYNAMODB_TABLE_NAME)

    def create_or_update_user(self, user_id: str, apple_sub: str, email: Optional[str] = None, name: Optional[str] = None) -> Dict[str, Any]:
        """
        Creates or updates a user profile item (SK = PROFILE).
        """
        pk = f"USER#{user_id}"
        sk = "PROFILE"
        
        # Build update expression to avoid overwriting existing fields (like Spotify tokens)
        update_expr = "SET apple_sub = :apple_sub, entity_type = :entity_type"
        expr_attrs = {
            ":apple_sub": apple_sub,
            ":entity_type": "user"
        }
        
        if email:
            update_expr += ", email = :email"
            expr_attrs[":email"] = email
        if name:
            update_expr += ", display_name = :name"
            expr_attrs[":name"] = name
            
        try:
            self.table.update_item(
                Key={"PK": pk, "SK": sk},
                UpdateExpression=update_expr,
                ExpressionAttributeValues=expr_attrs,
                ReturnValues="ALL_NEW"
            )
            return self.get_user_profile(user_id)
        except Exception as e:
            print(f"DynamoDB user creation error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Database error during user profile write: {str(e)}"
            )

    def get_user_profile(self, user_id: str) -> Dict[str, Any]:
        """
        Retrieves the profile record (SK = PROFILE) for a user.
        """
        try:
            response = self.table.get_item(Key={"PK": f"USER#{user_id}", "SK": "PROFILE"})
            return response.get("Item", {})
        except Exception as e:
            print(f"DynamoDB fetch profile error: {e}")
            return {}

    def save_spotify_tokens(self, user_id: str, access_token: str, refresh_token: str, expires_in: int) -> None:
        """
        Caches Spotify API tokens securely on the user profile.
        """
        expires_at = int(time.time()) + expires_in
        try:
            self.table.update_item(
                Key={"PK": f"USER#{user_id}", "SK": "PROFILE"},
                UpdateExpression="SET spotify_access_token = :access_token, spotify_refresh_token = :refresh_token, spotify_token_expires_at = :expires_at, spotify_linked = :linked",
                ExpressionAttributeValues={
                    ":access_token": access_token,
                    ":refresh_token": refresh_token,
                    ":expires_at": expires_at,
                    ":linked": True
                }
            )
        except Exception as e:
            print(f"DynamoDB save Spotify tokens error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to link Spotify account credentials."
            )

    def add_item_to_queue(self, user_id: str, item_id: str, entity_type: str, metadata: Dict[str, Any]) -> None:
        """
        Adds a media item to the user's active queue.
        SK = QUEUE#<entityType>#<itemId>
        """
        pk = f"USER#{user_id}"
        sk = f"QUEUE#{entity_type.upper()}#{item_id}"
        
        item = {
            "PK": pk,
            "SK": sk,
            "entity_type": entity_type,
            "item_id": item_id,
            "added_at": int(time.time()),
            "is_completed": False,
            "metadata": metadata
        }
        try:
            self.table.put_item(Item=item)
        except Exception as e:
            print(f"DynamoDB add queue item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add item to your active list."
            )

    def get_active_queue(self, user_id: str, entity_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Retrieves all items currently in the user's active queue.
        Optional filter by entity_type (song, album, etc.).
        """
        pk = f"USER#{user_id}"
        prefix = "QUEUE#"
        if entity_type:
            prefix += f"{entity_type.upper()}#"
            
        try:
            response = self.table.query(
                KeyConditionExpression="PK = :pk AND begins_with(SK, :prefix)",
                ExpressionAttributeValues={":pk": pk, ":prefix": prefix}
            )
            return response.get("Items", [])
        except Exception as e:
            print(f"DynamoDB fetch queue error: {e}")
            return []

    def log_item_completed(self, user_id: str, item_id: str, entity_type: str, rating: int, comment: str) -> None:
        """
        Moves an active queue item into a completed item record.
        Deletes the QUEUE record and inserts the COMPLETED record.
        """
        pk = f"USER#{user_id}"
        queue_sk = f"QUEUE#{entity_type.upper()}#{item_id}"
        completed_sk = f"COMPLETED#{entity_type.upper()}#{item_id}"
        
        # 1. Fetch metadata from current queue item
        try:
            queue_response = self.table.get_item(Key={"PK": pk, "SK": queue_sk})
            queue_item = queue_response.get("Item")
            if not queue_item:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Item was not found in your active queue."
                )
            
            # 2. Write completed log item
            completed_item = {
                "PK": pk,
                "SK": completed_sk,
                "entity_type": entity_type,
                "item_id": item_id,
                "completed_at": int(time.time()),
                "is_completed": True,
                "rating": rating,
                "comment": comment,
                "metadata": queue_item.get("metadata", {}),
                # Setup Global Secondary Index attributes for rating query
                "GSI1_PK": pk,
                "GSI1_SK": f"RATING#{rating}#COMPLETED#{entity_type.upper()}#{item_id}"
            }
            
            # Transactionally delete from queue and write to completed
            # To keep Lambda cost/complexity minimal, execute sequentially
            self.table.put_item(Item=completed_item)
            self.table.delete_item(Key={"PK": pk, "SK": queue_sk})
            
        except HTTPException:
            raise
        except Exception as e:
            print(f"DynamoDB complete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to record completion."
            )

    def get_completed_list(self, user_id: str, entity_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        Fetches all completed items logged by the user.
        """
        pk = f"USER#{user_id}"
        prefix = "COMPLETED#"
        if entity_type:
            prefix += f"{entity_type.upper()}#"
            
        try:
            response = self.table.query(
                KeyConditionExpression="PK = :pk AND begins_with(SK, :prefix)",
                ExpressionAttributeValues={":pk": pk, ":prefix": prefix}
            )
            return response.get("Items", [])
        except Exception as e:
            print(f"DynamoDB fetch completions error: {e}")
            return []

    def delete_item(self, user_id: str, item_id: str, entity_type: str, queue_only: bool = True) -> None:
        """
        Deletes a media item from the active queue or completed log.
        """
        pk = f"USER#{user_id}"
        prefix = "QUEUE" if queue_only else "COMPLETED"
        sk = f"{prefix}#{entity_type.upper()}#{item_id}"
        
        try:
            self.table.delete_item(Key={"PK": pk, "SK": sk})
        except Exception as e:
            print(f"DynamoDB delete item error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete the item."
            )

db_service = DynamoDBService()

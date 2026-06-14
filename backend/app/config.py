import os
import boto3
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Core Application Settings
    ENV: str = "dev"
    JWT_SECRET: str = "supersecretjwttoken"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 24 * 7  # 1 week

    # DynamoDB Configuration
    DYNAMODB_TABLE_NAME: str = "ListenListTable"
    AWS_REGION: str = "us-east-1"

    # Spotify Integration
    SPOTIFY_CLIENT_ID: Optional[str] = None
    SPOTIFY_CLIENT_SECRET: Optional[str] = None
    SPOTIFY_REDIRECT_URI: str = "https://d15girke7x008z.cloudfront.net"

    # Auth0 Configuration
    AUTH0_DOMAIN: str = ""
    AUTH0_CLIENT_ID: str = ""
    AUTH0_AUDIENCE: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()

# Bootstrap parameters from SSM Parameter Store if running in AWS environment
if os.environ.get("AWS_LAMBDA_FUNCTION_NAME"):
    ssm = boto3.client("ssm", region_name=settings.AWS_REGION)
    
    def get_parameter(name: str, secure: bool = False) -> Optional[str]:
        try:
            response = ssm.get_parameter(Name=name, WithDecryption=secure)
            return response["Parameter"]["Value"]
        except Exception as e:
            print(f"Error fetching SSM parameter {name}: {e}")
            return None

    env = settings.ENV
    # Fetch secrets securely from SSM Parameter Store
    spotify_secret = get_parameter(f"/listenlist/{env}/spotify/client_secret", secure=True)
    if spotify_secret:
        settings.SPOTIFY_CLIENT_SECRET = spotify_secret

    spotify_id = get_parameter(f"/listenlist/{env}/spotify/client_id", secure=False)
    if spotify_id:
        settings.SPOTIFY_CLIENT_ID = spotify_id

    jwt_secret = get_parameter(f"/listenlist/{env}/jwt_secret", secure=True)
    if jwt_secret:
        settings.JWT_SECRET = jwt_secret

    auth0_domain = get_parameter(f"/listenlist/{env}/auth0/domain", secure=False)
    if auth0_domain:
        settings.AUTH0_DOMAIN = auth0_domain

    auth0_client_id = get_parameter(f"/listenlist/{env}/auth0/client_id", secure=False)
    if auth0_client_id:
        settings.AUTH0_CLIENT_ID = auth0_client_id

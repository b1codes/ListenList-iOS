resource "aws_ssm_parameter" "spotify_client_id" {
  name        = "/${var.app_name}/${var.environment}/spotify/client_id"
  description = "Spotify Web API Client ID"
  type        = "String"
  value       = "PLACEHOLDER_SPOTIFY_CLIENT_ID"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "spotify_client_secret" {
  name        = "/${var.app_name}/${var.environment}/spotify/client_secret"
  description = "Spotify Web API Client Secret"
  type        = "SecureString"
  value       = "PLACEHOLDER_SPOTIFY_CLIENT_SECRET"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.app_name}/${var.environment}/jwt_secret"
  description = "JWT Token signing key secret"
  type        = "SecureString"
  value       = "PLACEHOLDER_JWT_SECRET"

  lifecycle {
    ignore_changes = [value]
  }
}

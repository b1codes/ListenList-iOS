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

resource "aws_ssm_parameter" "auth0_domain" {
  name        = "/${var.app_name}/${var.environment}/auth0/domain"
  description = "Auth0 tenant domain"
  type        = "String"
  value       = "PLACEHOLDER_AUTH0_DOMAIN"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "auth0_client_id" {
  name        = "/${var.app_name}/${var.environment}/auth0/client_id"
  description = "Auth0 iOS native app client ID"
  type        = "String"
  value       = "PLACEHOLDER_AUTH0_CLIENT_ID"

  lifecycle {
    ignore_changes = [value]
  }
}

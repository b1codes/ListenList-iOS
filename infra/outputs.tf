output "api_endpoint" {
  description = "The HTTP API Gateway URL to point your iOS app towards"
  value       = aws_apigatewayv2_stage.api_stage.invoke_url
}

output "ecr_repository_url" {
  description = "The ECR repository URL to push your backend Docker image to"
  value       = aws_ecr_repository.backend_repo.repository_url
}

output "dynamodb_table_name" {
  description = "The DynamoDB Single-Table Name"
  value       = aws_dynamodb_table.listenlist_table.name
}

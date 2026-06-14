# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# CloudWatch Logging Policy
resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.app_name}-${var.environment}-lambda-logging"
  description = "IAM policy for logging from Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# DynamoDB Access Policy
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.app_name}-${var.environment}-lambda-dynamodb"
  description = "Allow Lambda to access DynamoDB Table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = [
          aws_dynamodb_table.listenlist_table.arn,
          "${aws_dynamodb_table.listenlist_table.arn}/index/*"
        ]
      }
    ]
  })
}

# SSM Parameter Store Decryption Policy
resource "aws_iam_policy" "lambda_ssm" {
  name        = "${var.app_name}-${var.environment}-lambda-ssm"
  description = "Allow Lambda to fetch SSM parameter configs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/${var.app_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# Attach policies
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_db" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ssm_params" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ssm.arn
}

resource "aws_lambda_function" "api_lambda" {
  function_name    = "${var.app_name}-${var.environment}-api"
  role             = aws_iam_role.lambda_role.arn
  package_type     = "Zip"
  runtime          = "python3.11"
  handler          = "app.main.handler"
  filename         = "${path.module}/../backend/function.zip"
  source_code_hash = filebase64sha256("${path.module}/../backend/function.zip")
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      ENV                 = var.environment
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.listenlist_table.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_iam_role_policy_attachment.lambda_db,
    aws_iam_role_policy_attachment.lambda_ssm_params
  ]
}

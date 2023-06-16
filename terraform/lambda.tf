# Protected Lambda function
variable "function_name" {
  type    = string
  default = "lambda_defender_demo"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name_prefix        = "lambda_"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda" {
  name_prefix = "lambda_"
  role        = aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:ca-central-1:${data.aws_caller_identity.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:ca-central-1:${data.aws_caller_identity.account_id}:log-group:/aws/lambda/lambda_defender_demo${var.function_name}:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:DeleteObject"]
        Resource = "arn:aws:s3:::*"
      }
    ]
  })
}

data "archive_file" "function" {
  source_file = "../handler/lambda_handler.py"
  output_path = "lambda_handler.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.9"
  filename      = data.archive_file.function.output_path
  handler       = "lambda_handler.delete"

  source_code_hash = data.archive_file.function.output_base64sha256
}



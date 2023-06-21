# Protected Lambda function

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

data "archive_file" "function" {
  source_file = "../../handler/lambda_handler.py"
  output_path = "lambda_handler.zip"
  type        = "zip"
}

resource "aws_lambda_function" "prisma" {
  function_name                  = "prismacloud-ds-remediation-${random_string.this.result}"
  role                           = aws_iam_role.lambda_execution_role.arn
  runtime                        = "python3.9"
  filename                       = data.archive_file.function.output_path
  handler                        = "lambda_handler.quarantine"
  source_code_hash               = data.archive_file.function.output_base64sha256
  reserved_concurrent_executions = 10

  environment {
    variables = {
      "S3_QUARANTINE_BUCKET_NAME" = aws_s3_bucket.quarantine.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "lambda" {
  event_source_arn = aws_sqs_queue.alert_queue.arn
  function_name    = aws_lambda_function.prisma.arn
}

resource "aws_s3_bucket" "quarantine" {
  bucket = "prismacloud-ds-quarantine-${random_string.this.result}"
}

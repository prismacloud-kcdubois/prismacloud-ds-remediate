data "aws_iam_policy_document" "sqs" {
  statement {
    sid    = "pub1"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.prismacloud.arn]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.alert_queue.arn]
  }

  statement {
    sid    = "sub1"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.lambda_execution_role.arn]
    }

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage"
    ]
    resources = [aws_sqs_queue.alert_queue.arn]
  }
}

resource "aws_sqs_queue" "alert_queue" {
  name                      = "prismacloud-ds-${random_string.this.result}"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue_policy" "alert_queue" {
  policy    = data.aws_iam_policy_document.sqs.json
  queue_url = aws_sqs_queue.alert_queue.url
}

resource "random_string" "this" {
  length  = 12
  upper   = false
  special = false
}


output "sqs_queue_url" {
  value = aws_sqs_queue.alert_queue.url
}

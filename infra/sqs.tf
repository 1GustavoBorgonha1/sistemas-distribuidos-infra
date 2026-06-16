# --- Dead Letter Queue ---
resource "aws_sqs_queue" "loan_events_dlq" {
  name                      = "${local.name_prefix}-loan-events-dlq"
  message_retention_seconds = 1209600 # 14 dias
  tags                      = local.common_tags
}

# --- Fila de eventos de empréstimo (backend publica, Lambda consome) ---
resource "aws_sqs_queue" "loan_events" {
  name                       = "${local.name_prefix}-loan-events"
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.loan_events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = local.common_tags
}

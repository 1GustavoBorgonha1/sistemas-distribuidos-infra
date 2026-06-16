# --- Empacota o código da Lambda ---
data "archive_file" "notify" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/notify"
  output_path = "${path.module}/build/notify.zip"
}

# --- Role de execução da Lambda ---
resource "aws_iam_role" "lambda_notify" {
  name = "${local.name_prefix}-lambda-notify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_notify.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name = "${local.name_prefix}-lambda-sqs"
  role = aws_iam_role.lambda_notify.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
      ]
      Resource = aws_sqs_queue.loan_events.arn
    }]
  })
}

# --- Função Lambda ---
resource "aws_lambda_function" "notify" {
  function_name    = "${local.name_prefix}-notify"
  role             = aws_iam_role.lambda_notify.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.notify.output_path
  source_code_hash = data.archive_file.notify.output_base64sha256
  timeout          = 30
  tags             = local.common_tags
}

# --- Liga a fila à Lambda ---
resource "aws_lambda_event_source_mapping" "notify" {
  event_source_arn                   = aws_sqs_queue.loan_events.arn
  function_name                      = aws_lambda_function.notify.arn
  batch_size                         = 10
  function_response_types            = ["ReportBatchItemFailures"]
  maximum_batching_window_in_seconds = 5
}

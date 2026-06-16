output "url_api" {
  value = "https://${local.api_domain}"
}

output "url_frontend" {
  value = "https://${local.front_domain}"
}

output "k3s_master_public_ip" {
  value       = aws_eip.k3s_master.public_ip
  description = "IP público do K3s master"
}

output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

output "alb_backend_dns" {
  value = aws_lb.backend.dns_name
}

output "sqs_queue_url" {
  value       = aws_sqs_queue.loan_events.url
  description = "URL da fila de eventos de empréstimo"
}

output "sqs_dlq_url" {
  value = aws_sqs_queue.loan_events_dlq.url
}

output "lambda_notify_name" {
  value = aws_lambda_function.notify.function_name
}

output "s3_frontend_bucket" {
  value       = aws_s3_bucket.frontend.bucket
  description = "Secret S3_BUCKET no repo de frontend"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "Secret CLOUDFRONT_DISTRIBUTION_ID no repo de frontend"
}

output "ssm_kubeconfig_path" {
  value = aws_ssm_parameter.k3s_kubeconfig.name
}

output "deployed_image" {
  value       = local.backend_image_ref
  description = "Imagem do backend implantada no cluster"
}

output "backend_image_repo" {
  value       = var.backend_image
  description = "Repositório da imagem (sem tag) — usado pelo workflow de deploy"
}

output "app_name" {
  value = var.project_name
}

output "k8s_namespace" {
  value = var.k8s_namespace
}

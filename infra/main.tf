terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Valores em backend.hcl: terraform init -backend-config=backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  env          = var.env
  name_prefix  = "${var.project_name}-${var.env}"
  front_domain = var.base_domain
  api_domain   = "api.${var.base_domain}"

  backend_image_ref = "${var.backend_image}:${var.backend_image_tag}"


  lb_name = substr("${local.name_prefix}-be", 0, 32)
  tg_name = substr("${local.name_prefix}-tg", 0, 32)

  common_tags = {
    Environment = var.env
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

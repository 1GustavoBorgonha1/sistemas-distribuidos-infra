variable "project_name" {
  description = "Nome do projeto — prefixo de todos os recursos (ex: cut-url)"
  type        = string
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Ambiente lógico usado nos nomes/paths (ex: prod)"
  type        = string
  default     = "prod"
}

variable "state_bucket_name" {
  description = "Bucket S3 do state remoto da infra. Default: <project>-tfstate"
  type        = string
  default     = ""
}

variable "lock_table_name" {
  description = "Tabela DynamoDB de lock. Default: <project>-tfstate-lock"
  type        = string
  default     = ""
}

variable "github_org" {
  description = "Organização/usuário dono dos repositórios no GitHub"
  type        = string
}

variable "infra_repo_name" {
  description = "Repositório de infraestrutura (este projeto Terraform)"
  type        = string
}

variable "frontend_repo_name" {
  description = "Repositório do frontend estático"
  type        = string
}

variable "backend_repo_name" {
  description = "Repositório do backend (build/push + deploy no K3s via SSM)"
  type        = string
}

variable "create_frontend_role" {
  description = "Criar a role OIDC para o repo de frontend (deploy S3 + CloudFront)"
  type        = bool
  default     = true
}

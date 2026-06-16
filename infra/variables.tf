# --- Identidade do projeto ---
variable "project_name" {
  description = "Nome do projeto — prefixo de todos os recursos. Deve bater com o bootstrap."
  type        = string
}

variable "env" {
  description = "Ambiente lógico (ex: prod). Usado em nomes e paths SSM."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

# --- Aplicação (backend em Docker) ---
variable "backend_image" {
  description = "Imagem do backend no Docker Hub, sem a tag (ex: gustavoborgonha/bibliotecasys-backend)"
  type        = string
}

variable "backend_image_tag" {
  description = "Tag da imagem do backend a ser implantada"
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  description = "Porta que o container do backend expõe"
  type        = number
  default     = 3000
}

variable "backend_node_port" {
  description = "NodePort do Service do backend no K3s (alvo do ALB)"
  type        = number
  default     = 30080
}

variable "backend_replicas" {
  description = "Número de réplicas do backend"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Path de health check do backend (ALB + probes)"
  type        = string
  default     = "/health"
}

variable "jwt_secret" {
  description = "Segredo de assinatura do JWT da aplicação"
  type        = string
  sensitive   = true
}

variable "k8s_namespace" {
  description = "Namespace onde a aplicação roda"
  type        = string
  default     = "app"
}

# --- Dados in-cluster (MongoDB + Redis no K3s) ---
variable "mongo_image" {
  description = "Imagem do MongoDB"
  type        = string
  default     = "mongo:7"
}

variable "mongo_db_name" {
  description = "Nome do banco no MongoDB"
  type        = string
  default     = "bibliotecasys"
}

variable "mongo_storage_size" {
  description = "Tamanho do volume persistente do MongoDB"
  type        = string
  default     = "5Gi"
}

variable "redis_image" {
  description = "Imagem do Redis"
  type        = string
  default     = "redis:7-alpine"
}

# --- Rede ---
variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da Subnet Pública A (AZ a)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR da Subnet Pública B (AZ b)"
  type        = string
  default     = "10.0.2.0/24"
}

# --- Cluster K3s ---
variable "master_instance_type" {
  description = "Tipo de instância do K3s master"
  type        = string
  default     = "t3.small"
}

variable "worker_instance_type" {
  description = "Tipo de instância dos K3s workers"
  type        = string
  default     = "t3.small"
}

variable "worker_count" {
  description = "Número desejado de workers"
  type        = number
  default     = 2
}

variable "worker_min_count" {
  description = "Número mínimo de workers"
  type        = number
  default     = 1
}

variable "worker_max_count" {
  description = "Número máximo de workers"
  type        = number
  default     = 3
}

variable "ec2_key_name" {
  description = "Key Pair EC2 para SSH (opcional)"
  type        = string
  default     = ""
}

# --- DNS / TLS (Cloudflare + ACM) ---
variable "base_domain" {
  description = "Domínio do frontend (ex: yan.tec.br). A API fica em api.<domínio>."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Token da API do Cloudflare"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID do Cloudflare"
  type        = string
}

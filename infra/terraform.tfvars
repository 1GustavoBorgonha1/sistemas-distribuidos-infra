project_name = "sistemas-distribuidos"
env          = "prod"
aws_region   = "us-east-1"

backend_image          = "gustavoborgonha/bibliotecasys-backend"
backend_image_tag      = "latest"
backend_container_port = 3000
backend_node_port      = 30080
backend_replicas       = 2
health_check_path      = "/health"

# Dados in-cluster
mongo_db_name = "bibliotecasys"

# Domínio
base_domain = "yan.tec.br"

# Sensíveis (passar via TF_VAR_*, não commitar):
#   jwt_secret, cloudflare_api_token, cloudflare_zone_id

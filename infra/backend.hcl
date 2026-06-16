# Config do backend remoto (valores vindos dos outputs do projeto bootstrap).
# Copie para backend.hcl e use: terraform init -backend-config=backend.hcl
# Estes valores NÃO são segredos — pode commitar backend.hcl.
bucket         = "sistemas-distribuidos-tfstate"
key            = "infra/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "sistemas-distribuidos-tfstate-lock"

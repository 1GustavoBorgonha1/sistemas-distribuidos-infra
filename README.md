# sistemas-distribuidos-infra

Template Terraform reutilizável para projetos com **frontend estático + backend em Docker + PostgreSQL**, na AWS.

Provisiona, a partir de uma imagem publicada no Docker Hub:

- **Frontend estático** → S3 + CloudFront (HTTPS via ACM, DNS no Cloudflare)
- **Backend (Docker)** → cluster K3s (1 master EC2 + ASG de workers), atrás de um ALB
- **Banco** → RDS PostgreSQL (privado)
- **CI/CD** → OIDC do GitHub Actions + roles IAM

O backend é buscado no Docker Hub pelo nome configurado em `backend_image` e implantado
no cluster automaticamente.

## Por que dois projetos Terraform?

O repositório original misturava a infra de CI/CD (OIDC provider + roles IAM que os
próprios workflows usam para autenticar) com a infra do app, num único state. Isso causava:

1. **Ovo-e-galinha**: o primeiro `apply` tinha que ser local, porque a role que o workflow
   usa só passava a existir _depois_ do apply.
2. **Destroy quebrado pelo Actions**: o `terraform destroy` apagava a própria role/OIDC que
   estava autenticando a execução.
3. O bucket S3 + DynamoDB do backend remoto não eram criados por ninguém (pré-requisito manual).

A solução é separar em duas camadas:

```
bootstrap/   → state local. Cria UMA vez: bucket+lock do state remoto, OIDC e roles IAM.
               Raramente muda; raramente é destruído.
infra/       → state remoto (no bucket criado pelo bootstrap). Toda a infra do app.
               Criada/destruída à vontade pelo Actions, sem tocar nas credenciais de CI/CD.
```

Como as roles de CI/CD vivem no `bootstrap`, o `destroy` da `infra` pelo Actions funciona —
ele não derruba a credencial que está usando.

## Setup de um projeto novo (do zero)

### 1. Bootstrap (uma vez, local)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # edite project_name, github_org, repos
terraform init
terraform apply
```

Anote os outputs:

- `state_bucket` / `lock_table` → vão para `infra/backend.hcl`
- `github_role_infra_arn` → secret `AWS_ROLE_ARN_INFRA` no repo de infra
- `github_role_frontend_arn` → secret `AWS_ROLE_ARN` no repo de frontend

> Guarde `bootstrap/terraform.tfstate` em local seguro (não há segredos de app nele, mas é
> o que controla as credenciais de CI/CD). Pode migrar para um backend remoto depois, se quiser.

### 2. Infra

```bash
cd ../infra
cp terraform.tfvars.example terraform.tfvars   # project_name, backend_image, base_domain...
cp backend.hcl.example backend.hcl             # preencha com os outputs do bootstrap
terraform init -backend-config=backend.hcl
terraform apply \
  -var="db_password=..." \
  -var="cloudflare_api_token=..." \
  -var="cloudflare_zone_id=..."
```

O master do K3s, ao subir, já cria namespace, secret com a `DATABASE_URL` e aplica o
Deployment/Service — ou seja, `apply` entrega o app rodando.

### 3. Secrets nos repositórios GitHub

| Repo      | Secrets                                                                            |
| --------- | ---------------------------------------------------------------------------------- |
| infra     | `AWS_ROLE_ARN_INFRA`, `DB_PASSWORD`, `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID`   |
| frontend  | `AWS_ROLE_ARN`, `S3_BUCKET` (output), `CLOUDFRONT_DISTRIBUTION_ID` (output)         |
| backend   | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` (só build & push da imagem)                 |

Commit em `infra` no `main` dispara `apply`. Mudou só a imagem do backend? Rode o workflow
**Deploy App** informando a nova tag — ele faz `kubectl set image` sem recriar o cluster.

## Adaptando para um app diferente

Tudo é parametrizado em `infra/variables.tf`. Os ajustes típicos:

- `project_name` — prefixo de todos os recursos (precisa bater com o bootstrap)
- `backend_image` / `backend_image_tag` — imagem no Docker Hub
- `backend_container_port` — porta que o container expõe (default 3000)
- `health_check_path` — path de health check (default `/`)
- `db_name`, `base_domain`, CIDRs, tipos de instância...

A aplicação só precisa ler `DATABASE_URL` do ambiente (injetada via Secret `app-secrets`)
e escutar na `backend_container_port`.
```

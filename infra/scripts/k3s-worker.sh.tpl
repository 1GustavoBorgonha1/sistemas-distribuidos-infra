#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/k3s-worker-bootstrap.log) 2>&1

REGION="${region}"
WORKSPACE="${workspace}"
MASTER_IP="${master_private_ip}"

echo "[1/3] Instalando dependências..."
dnf install -y jq

echo "[2/3] Aguardando token K3s válido no SSM..."
K3S_TOKEN=""
until [ -n "$K3S_TOKEN" ] && [ "$K3S_TOKEN" != "bootstrap-placeholder" ]; do
  K3S_TOKEN=$(aws ssm get-parameter \
    --name "/$WORKSPACE/k3s/token" \
    --with-decryption \
    --region "$REGION" \
    --query "Parameter.Value" \
    --output text 2>/dev/null || echo "")
  if [ -z "$K3S_TOKEN" ] || [ "$K3S_TOKEN" = "bootstrap-placeholder" ]; then
    echo "  Token ainda não disponível, aguardando 15s..."
    sleep 15
  fi
done
echo "Token K3s obtido."

echo "[3/3] Ingressando no cluster K3s..."
curl -sfL https://get.k3s.io | \
  K3S_URL="https://$MASTER_IP:6443" \
  K3S_TOKEN="$K3S_TOKEN" \
  sh -

echo "Worker K3s ingressou no cluster com sucesso!"

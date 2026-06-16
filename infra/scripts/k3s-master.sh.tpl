#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/k3s-bootstrap.log) 2>&1

REGION="${region}"
WORKSPACE="${workspace}"
NAMESPACE="${namespace}"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "[1/7] Instalando dependências..."
dnf install -y jq

echo "[2/7] Instalando K3s server..."
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)
echo "IP público: $PUBLIC_IP"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --tls-san $PUBLIC_IP \
  --disable traefik \
  --write-kubeconfig-mode 644" sh -

echo "[3/7] Aguardando K3s ficar pronto..."
until kubectl get nodes &>/dev/null; do
  echo "  aguardando API server..."
  sleep 5
done
echo "K3s pronto."

echo "[4/7] Publicando credenciais do cluster no SSM..."
K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
aws ssm put-parameter --name "/$WORKSPACE/k3s/token" \
  --value "$K3S_TOKEN" --type "SecureString" --overwrite --region "$REGION"

KUBECONFIG_CONTENT=$(sed "s/127.0.0.1/$PUBLIC_IP/g" /etc/rancher/k3s/k3s.yaml)
aws ssm put-parameter --name "/$WORKSPACE/k3s/kubeconfig" \
  --value "$KUBECONFIG_CONTENT" --type "SecureString" --overwrite --region "$REGION"

echo "[5/7] Criando namespace e secret da aplicação..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "  aguardando JWT_SECRET no SSM..."
JWT=""
until [ -n "$JWT" ] && [ "$JWT" != "None" ]; do
  JWT=$(aws ssm get-parameter --name "/$WORKSPACE/app/jwt_secret" \
    --with-decryption --region "$REGION" \
    --query "Parameter.Value" --output text 2>/dev/null || echo "")
  [ -z "$JWT" ] || [ "$JWT" = "None" ] && { echo "  ainda indisponível, 15s..."; sleep 15; }
done

kubectl create secret generic app-secrets \
  --from-literal=JWT_SECRET="$JWT" \
  --namespace="$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "[6/7] Aplicando MongoDB e Redis..."
cat > /tmp/mongo.yaml <<'MONGO_EOF'
${mongo_manifest}
MONGO_EOF
cat > /tmp/redis.yaml <<'REDIS_EOF'
${redis_manifest}
REDIS_EOF
kubectl apply -f /tmp/mongo.yaml
kubectl apply -f /tmp/redis.yaml

echo "[7/7] Aplicando a aplicação..."
cat > /tmp/app.yaml <<'APP_EOF'
${app_manifest}
APP_EOF
kubectl apply -f /tmp/app.yaml

echo "Bootstrap do K3s master concluído com sucesso!"

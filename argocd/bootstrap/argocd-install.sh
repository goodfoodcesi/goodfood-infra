#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Bootstrap ArgoCD..."

# 1. Create namespace
echo "📁 Creating argocd namespace (if not exists)..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD server
echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait \
  --for=condition=available \
  deployment/argocd-server \
  -n argocd \
  --timeout=300s

# 4. Apply ArgoCD ingress
echo "🌐 Applying ArgoCD ingress..."
kubectl apply -f "$ROOT_DIR/argocd-ingress.yaml"

# 5. Get initial admin password
echo "🔑 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✅ ArgoCD installed successfully!"
echo ""
echo "🌍 URL      : https://argocd.goodfood.test"
echo "👤 Username : admin"
echo "🔑 Password : $ARGOCD_PASSWORD"
echo ""
echo "➡️ Next step:"
echo "   kubectl apply -f argocd/app-of-apps.yaml"
echo ""

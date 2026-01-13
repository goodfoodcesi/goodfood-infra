#!/bin/bash
set -e

echo "🚀 Bootstrap ArgoCD..."

# 1. Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# 4. Expose ArgoCD
echo "🌐 Exposing ArgoCD UI..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 5. Get initial password
echo "🔑 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# 6. Wait for LoadBalancer IP
echo "⏳ Waiting for LoadBalancer IP..."
ARGOCD_IP=""
while [ -z "$ARGOCD_IP" ]; do
  ARGOCD_IP=$(kubectl get svc argocd-server -n argocd \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$ARGOCD_IP" ] && sleep 5
done

echo ""
echo "ArgoCD installed successfully!"
echo ""
echo " ArgoCD URL: https://$ARGOCD_IP"
echo " Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""
echo " Commande à jouer après: "
echo " kubectl apply -f argocd/app-of-apps.yaml"
echo ""
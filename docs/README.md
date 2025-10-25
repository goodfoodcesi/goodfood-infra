# GoodFood Infrastructure Documentation

Documentation complète pour déployer et gérer l'infrastructure GoodFood.

## 📚 Table des matières

### Setup Initial
1. [🏠 Setup Local (Minikube)](./01-local-dev-setup.md)
2. [🖥️ Setup Preprod (K3s Proxmox)](./02-preprod-setup.md)
3. [🚀 Guide ArgoCD](./03-argocd-guide.md)

### Gestion quotidienne
4. [🔐 Gestion des Secrets](./04-secrets-management.md)
5. [📦 Déployer une nouvelle version](./05-deploy-new-version.md)
6. [🔧 Dépannage](./99-troubleshooting.md)

---

## 🌍 Environnements

| Environnement | Infrastructure | Namespace | URL |
|---------------|---------------|-----------|-----|
| **Dev** | Minikube (local) | `default` | http://dev.goodfood.test |
| **Preprod** | K3s Proxmox (3 VMs) | `preprod` | http://preprod.goodfood.test |
| **Prod** | *À venir* | `production` | https://goodfood.com |

---

## 🛠️ Stack technique

- **Orchestration:** Kubernetes (Minikube / K3s)
- **GitOps:** ArgoCD
- **IaC:** Terraform (Proxmox)
- **Config Management:** Ansible
- **Registry:** GitHub Container Registry + Scaleway
- **Monitoring:** *À venir* (Grafana + Loki)

---

## 🚀 Quick Start

### Dev Local (Minikube)
```bash
# 1. Démarrer Minikube
minikube start
minikube tunnel  # Dans un autre terminal

# 2. Créer les secrets
make secrets-dev

# 3. Installer ArgoCD
kubectl apply -k kube/argocd/install/

# 4. Déployer l'app
kubectl apply -f kube/argocd/applications/goodfood-dev.yaml
# Puis SYNC dans l'UI ArgoCD
```

**[→ Guide complet Local Dev](./01-local-dev-setup.md)**

---

### Preprod (K3s Proxmox)
```bash
# 1. Provisionner l'infra
cd terraform/k3s-proxmox/
terraform apply

# 2. Installer K3s
cd ../../ansible/k3s-ansible/
source .env
ansible-playbook playbooks/site.yml -i inventory.yml

# 3. Déployer l'app
ansible-playbook playbooks/deploy-goodfood.yml -i inventory.yml
```

**[→ Guide complet Preprod](./02-preprod-setup.md)**

---

# Makefile - GoodFood Infrastructure
# Commandes pour gérer dev (Minikube) et preprod (K3s Proxmox)

.PHONY: help

# Couleurs pour les messages
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Configs
MINIKUBE_CONFIG := ~/.kube/config
K3S_CONFIG := ~/.kube/proxmox/config
TERRAFORM_DIR := terraform/k3s-proxmox
ANSIBLE_DIR := ansible/k3s-ansible

#==============================================================================
# HELP
#==============================================================================

help: ## Afficher l'aide
	@echo "$(CYAN)🚀 GoodFood Infrastructure$(NC)"
	@echo ""
	@echo "$(GREEN)Utilisation:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)📚 Documentation complète:$(NC) docs/"

#==============================================================================
# KUBERNETES - DEV (Minikube)
#==============================================================================

dev: ## Lancer k9s sur Minikube (dev)
	@echo "$(GREEN)🚀 Lancement de k9s sur Minikube...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) k9s

minikube-start: ## Démarrer Minikube
	@echo "$(GREEN)🚀 Démarrage de Minikube...$(NC)"
	@minikube start
	@echo "$(GREEN)✅ Minikube démarré$(NC)"
	@echo "$(YELLOW)💡 Lance 'minikube tunnel' dans un autre terminal$(NC)"

minikube-stop: ## Arrêter Minikube
	@echo "$(YELLOW)⏸️  Arrêt de Minikube...$(NC)"
	@minikube stop

minikube-delete: ## Supprimer Minikube
	@echo "$(RED)🗑️  Suppression de Minikube...$(NC)"
	@minikube delete

secrets-dev: ## Créer les secrets dev (namespace: default)
	@echo "$(GREEN)🔐 Création des secrets dev...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl apply -f kube/dev/03-secrets/
	@echo "$(GREEN)✅ Secrets créés$(NC)"

context-dev: ## Switcher vers le contexte Minikube
	@echo "$(GREEN)🔄 Switch vers Minikube$(NC)"
	@kubectl config use-context minikube
	@kubectl config current-context

#==============================================================================
# KUBERNETES - PREPROD (K3s Proxmox)
#==============================================================================

preprod: ## Lancer k9s sur K3s Proxmox (preprod)
	@echo "$(GREEN)🚀 Lancement de k9s sur K3s...$(NC)"
	@KUBECONFIG=$(K3S_CONFIG) k9s

secrets-preprod: ## Créer les secrets preprod (namespace: preprod)
	@echo "$(GREEN)🔐 Création des secrets preprod...$(NC)"
	@KUBECONFIG=$(K3S_CONFIG) kubectl create namespace preprod --dry-run=client -o yaml | kubectl apply -f -
	@KUBECONFIG=$(K3S_CONFIG) kubectl apply -f kube/preprod/secrets/
	@echo "$(GREEN)✅ Secrets créés$(NC)"

context-preprod: ## Switcher vers le contexte K3s
	@echo "$(GREEN)🔄 Switch vers K3s$(NC)"
	@export KUBECONFIG=$(K3S_CONFIG) && kubectl config current-context

#==============================================================================
# ARGOCD
#==============================================================================

argocd-install: ## Installer ArgoCD sur Minikube
	@echo "$(GREEN)📦 Installation d'ArgoCD...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl apply -k kube/argocd/install/
	@echo "$(YELLOW)⏳ Attendre que les pods démarrent...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@echo "$(GREEN)✅ ArgoCD installé$(NC)"
	@echo ""
	@echo "$(CYAN)🔑 Mot de passe admin:$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
	@echo ""
	@echo "$(CYAN)🌐 Accéder à l'UI:$(NC)"
	@echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
	@echo "  open https://localhost:8080"

argocd-password: ## Afficher le mot de passe admin ArgoCD
	@echo "$(CYAN)🔑 Mot de passe admin ArgoCD:$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

argocd-ui: ## Lancer port-forward vers ArgoCD UI
	@echo "$(GREEN)🌐 Lancement du port-forward vers ArgoCD...$(NC)"
	@echo "$(CYAN)Ouvrir: https://localhost:8080$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-deploy-dev: ## Déployer l'app dev dans ArgoCD
	@echo "$(GREEN)📦 Déploiement de goodfood-dev dans ArgoCD...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl apply -f kube/argocd/applications/goodfood-dev.yaml
	@echo "$(GREEN)✅ Application créée$(NC)"
	@echo "$(YELLOW)💡 Aller dans l'UI ArgoCD et cliquer SYNC$(NC)"

argocd-deploy-preprod: ## Déployer l'app preprod dans ArgoCD
	@echo "$(GREEN)📦 Déploiement de goodfood-preprod dans ArgoCD...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl apply -f kube/argocd/applications/goodfood-preprod.yaml
	@echo "$(GREEN)✅ Application créée$(NC)"
	@echo "$(YELLOW)💡 Aller dans l'UI ArgoCD et cliquer SYNC$(NC)"

argocd-delete-dev: ## Supprimer l'app dev d'ArgoCD
	@echo "$(RED)🗑️  Suppression de goodfood-dev...$(NC)"
	@KUBECONFIG=$(MINIKUBE_CONFIG) kubectl delete -f kube/argocd/applications/goodfood-dev.yaml

#==============================================================================
# TERRAFORM - Infrastructure Proxmox
#==============================================================================

tf-init: ## Terraform init
	@echo "$(GREEN)🔧 Terraform init...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform init

tf-plan: ## Terraform plan
	@echo "$(GREEN)📋 Terraform plan...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform plan

tf-apply: ## Terraform apply (créer les VMs)
	@echo "$(GREEN)🚀 Terraform apply...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform apply
	@echo "$(GREEN)✅ Infrastructure créée$(NC)"

tf-destroy: ## Terraform destroy (détruire les VMs)
	@echo "$(RED)💥 Terraform destroy...$(NC)"
	@cd $(TERRAFORM_DIR) && terraform destroy

tf-output: ## Afficher les outputs Terraform
	@cd $(TERRAFORM_DIR) && terraform output

#==============================================================================
# ANSIBLE - Configuration K3s
#==============================================================================

ansible-install-k3s: ## Installer K3s sur les VMs Proxmox
	@echo "$(GREEN)📦 Installation de K3s via Ansible...$(NC)"
	@cd $(ANSIBLE_DIR) && \
		test -f .env && source .env && \
		ansible-playbook playbooks/site.yml -i inventory.yml
	@echo "$(GREEN)✅ K3s installé$(NC)"

ansible-deploy: ## Déployer l'app sur K3s via Ansible
	@echo "$(GREEN)🚀 Déploiement de l'app via Ansible...$(NC)"
	@cd $(ANSIBLE_DIR) && \
		ansible-playbook playbooks/deploy-goodfood.yml -i inventory.yml
	@echo "$(GREEN)✅ Application déployée$(NC)"

ansible-fetch-kubeconfig: ## Récupérer le kubeconfig K3s
	@echo "$(GREEN)📥 Récupération du kubeconfig...$(NC)"
	@cd $(ANSIBLE_DIR) && \
		ansible-playbook playbooks/fetch-kubeconfig.yml -i inventory.yml
	@echo "$(GREEN)✅ Kubeconfig enregistré$(NC)"

#==============================================================================
# WORKFLOWS COMPLETS
#==============================================================================

setup-dev: minikube-start secrets-dev argocd-install ## Setup complet dev (Minikube)
	@echo ""
	@echo "$(GREEN)✅ Setup dev terminé !$(NC)"
	@echo ""
	@echo "$(CYAN)Prochaines étapes:$(NC)"
	@echo "  1. Lance 'minikube tunnel' dans un autre terminal"
	@echo "  2. Lance 'make argocd-ui' pour accéder à ArgoCD"
	@echo "  3. Lance 'make argocd-deploy-dev' pour déployer l'app"
	@echo "  4. Dans ArgoCD UI, clique sur SYNC"

setup-preprod: tf-apply ansible-install-k3s ansible-fetch-kubeconfig secrets-preprod ## Setup complet preprod (K3s)
	@echo ""
	@echo "$(GREEN)✅ Setup preprod terminé !$(NC)"
	@echo ""
	@echo "$(CYAN)Prochaines étapes:$(NC)"
	@echo "  1. Lance 'make argocd-deploy-preprod'"
	@echo "  2. Dans ArgoCD UI, clique sur SYNC"

destroy-preprod: ## Détruire complètement preprod
	@echo "$(RED)💥 Destruction de preprod...$(NC)"
	@$(MAKE) tf-destroy
	@echo "$(GREEN)✅ Preprod détruit$(NC)"

#==============================================================================
# UTILITAIRES
#==============================================================================

status: ## Afficher le status des clusters
	@echo "$(CYAN)📊 Status des clusters$(NC)"
	@echo ""
	@echo "$(GREEN)Dev (Minikube):$(NC)"
	@minikube status 2>/dev/null || echo "  ❌ Minikube non démarré"
	@echo ""
	@echo "$(GREEN)Preprod (K3s):$(NC)"
	@KUBECONFIG=$(K3S_CONFIG) kubectl get nodes 2>/dev/null || echo "  ❌ K3s non accessible"

clean: ## Nettoyer les fichiers temporaires
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	@find . -name ".DS_Store" -delete
	@find . -name "*.retry" -delete
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

docs: ## Ouvrir la documentation
	@echo "$(CYAN)📚 Documentation:$(NC)"
	@open docs/README.md || cat docs/README.md

#==============================================================================
# PREPROD - ArgoCD sur K3s
#==============================================================================

preprod-install-argocd: ## Installer ArgoCD sur K3s
	@echo "$(GREEN)📦 Installation d'ArgoCD sur K3s...$(NC)"
	@cd $(ANSIBLE_DIR) && \
		ansible-playbook playbooks/install-argocd.yml -i inventory.yml
	@echo "$(GREEN)✅ ArgoCD installé sur K3s$(NC)"

preprod-argocd-password: ## Afficher le mot de passe ArgoCD preprod
	@echo "$(CYAN)🔑 Mot de passe admin ArgoCD (K3s):$(NC)"
	@KUBECONFIG=$(K3S_CONFIG) kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d && echo

preprod-argocd-ui: ## Port-forward vers ArgoCD preprod
	@echo "$(GREEN)🌐 Port-forward vers ArgoCD sur K3s...$(NC)"
	@echo "$(CYAN)Ouvrir: https://localhost:8081$(NC)"
	@KUBECONFIG=$(K3S_CONFIG) kubectl port-forward svc/argocd-server -n argocd 8081:443

preprod-deploy-app: ## Déployer goodfood-preprod via ArgoCD
	@echo "$(GREEN)📦 Déploiement de l'app via ArgoCD...$(NC)"
	@cd $(ANSIBLE_DIR) && \
		ansible-playbook playbooks/deploy-argocd-app.yml -i inventory.yml
	@echo "$(GREEN)✅ App déployée$(NC)"
	@echo "$(YELLOW)💡 Aller dans l'UI ArgoCD et cliquer SYNC$(NC)"

#==============================================================================
# WORKFLOWS COMPLETS - Preprod
#==============================================================================

setup-preprod-full: tf-apply ansible-install-k3s ansible-fetch-kubeconfig secrets-preprod preprod-install-argocd preprod-deploy-app ## Setup complet preprod avec ArgoCD
	@echo ""
	@echo "$(GREEN)✅ Setup preprod terminé !$(NC)"
	@echo ""
	@echo "$(CYAN)Prochaines étapes:$(NC)"
	@echo "  1. Lance 'make preprod-argocd-ui' pour accéder à ArgoCD"
	@echo "  2. Dans ArgoCD UI, clique sur SYNC"

.DEFAULT_GOAL := help
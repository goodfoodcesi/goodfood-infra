# Makefile pour automatiser le setup preprod

.PHONY: help setup-infra setup-k3s setup-argocd deploy-apps

help: ## Affiche l'aide
	@echo "Commandes disponibles:"
	@echo "  make setup-all         - Setup complet (infra + k3s + apps)"
	@echo "  make setup-infra       - Phase 1: Terraform"
	@echo "  make setup-k3s         - Phase 3: Installation K3s"
	@echo "  make setup-argocd      - Phase 4: Installation ArgoCD"
	@echo "  make deploy-apps       - Phase 5: Déploiement apps"
	@echo "  make destroy           - Détruire l'infrastructure"

setup-all: setup-infra accept-ssh setup-k3s setup-argocd deploy-apps ## Setup complet

setup-infra: ## Créer les VMs avec Terraform
	cd terraform/k3s-proxmox && terraform init && terraform apply

accept-ssh: ## Accepter les fingerprints SSH
	@bash scripts/accept-ssh-fingerprints.sh

setup-k3s: ## Installer K3s
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/site.yml -i inventory.yml && \
	ansible-playbook playbooks/install-rsync.yml -i inventory.yml

setup-argocd: ## Installer ArgoCD
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/install-argocd.yml -i inventory.yml
	@echo "ArgoCD password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

deploy-apps: ## Déployer les applications
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/deploy-secrets.yml -i inventory.yml && \
	ansible-playbook playbooks/deploy-argocd-app-preprod.yml -i inventory.yml

destroy: ## Détruire l'infrastructure
	cd terraform/k3s-proxmox && terraform destroy
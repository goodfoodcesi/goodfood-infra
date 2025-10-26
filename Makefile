# Makefile pour automatiser le setup preprod K3s

# Charger le .env depuis la racine
ifneq (,$(wildcard .env))
    include .env
    export
endif

.PHONY: help setup-all setup-infra update-inventory accept-ssh setup-k3s setup-argocd deploy-secrets deploy-apps fetch-kubeconfig destroy preprod

help: ## Affiche l'aide
	@echo ""
	@echo "🚀 Setup Preprod K3s - Commandes disponibles:"
	@echo ""
	@echo "  📦 Setup complet:"
	@echo "    make setup-all           - Setup complet automatique (infra + k3s + argocd + apps)"
	@echo ""
	@echo "  🔧 Étapes individuelles:"
	@echo "    make setup-infra         - Phase 1: Créer les VMs avec Terraform"
	@echo "    make update-inventory    - Phase 2: Mettre à jour l'inventory depuis Terraform"
	@echo "    make accept-ssh          - Phase 2b: Accepter les fingerprints SSH"
	@echo "    make setup-k3s           - Phase 3: Installer K3s + rsync"
	@echo "    make setup-argocd        - Phase 4: Installer ArgoCD"
	@echo "    make deploy-secrets      - Phase 5: Déployer les secrets"
	@echo "    make deploy-apps         - Phase 6: Déployer l'application preprod"
	@echo "    make fetch-kubeconfig    - (Optionnel) Récupérer le kubeconfig pour K9s"
	@echo ""
	@echo "  🗑️  Nettoyage:"
	@echo "    make destroy             - Détruire l'infrastructure Terraform"
	@echo ""

setup-all: setup-infra update-inventory accept-ssh setup-k3s setup-argocd deploy-secrets deploy-apps ## Setup complet automatique
	@echo ""
	@echo "✅ Setup preprod terminé !"
	@echo ""
	@echo "🌐 Accès ArgoCD:"
	@echo "   URL: http://argocd.goodfood.test"
	@echo "   User: admin"
	@echo "   Pass: (voir ci-dessus)"
	@echo ""
	@echo "💡 N'oubliez pas d'ajouter dans /etc/hosts:"
	@echo "   <MASTER_IP>  argocd.goodfood.test"
	@echo "   <MASTER_IP>  preprod.goodfood.test"
	@echo ""

setup-infra: ## Créer les VMs avec Terraform
	@echo "🏗️  Création de l'infrastructure..."
	cd terraform/k3s-proxmox && terraform init && terraform apply -auto-approve
	@echo "✅ Infrastructure créée"

update-inventory: ## Mettre à jour l'inventory depuis Terraform
	@echo "📝 Mise à jour de l'inventory..."
	@bash scripts/update-inventory-from-terraform.sh
	@echo "✅ Inventory mis à jour"

accept-ssh: ## Accepter les fingerprints SSH
	@echo "🔐 Acceptation des fingerprints SSH..."
	@bash scripts/accept-ssh-fingerprints.sh
	@echo "✅ Fingerprints acceptés"

setup-k3s: ## Installer K3s + rsync
	@echo "🐳 Installation de K3s..."
	@if [ -z "$$K3S_TOKEN" ]; then \
		echo "❌ Erreur: K3S_TOKEN non défini dans .env"; \
		exit 1; \
	fi
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/site.yml -i inventory.yml && \
	ansible-playbook playbooks/install-rsync.yml -i inventory.yml
	@echo "✅ K3s installé"

setup-argocd: ## Installer ArgoCD
	@echo "🔄 Installation d'ArgoCD..."
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/install-argocd.yml -i inventory.yml
	@echo ""
	@echo "🔑 ArgoCD admin password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""
	@echo "✅ ArgoCD installé"

deploy-secrets: ## Déployer les secrets
	@echo "🔐 Déploiement des secrets..."
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/create-secrets-preprod.yml -i inventory.yml
	@echo "✅ Secrets déployés"

deploy-apps: ## Déployer l'application preprod
	@echo "🚀 Déploiement de l'application..."
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/deploy-argocd-app.yml -i inventory.yml
	@echo "✅ Application déployée"

fetch-kubeconfig: ## Récupérer le kubeconfig pour K9s
	@echo "📥 Récupération du kubeconfig..."
	cd ansible/k3s-ansible && \
	ansible-playbook playbooks/fetch-kubeconfig.yml -i inventory.yml
	@echo "✅ Kubeconfig récupéré dans ~/.kube/proxmox/config"
	@echo ""
	@echo "💡 Pour utiliser ce kubeconfig:"
	@echo "   export KUBECONFIG=~/.kube/proxmox/config"
	@echo "   k9s"

destroy: ## Détruire l'infrastructure
	@echo "🗑️  Destruction de l'infrastructure..."
	cd terraform/k3s-proxmox && terraform destroy
	@echo "✅ Infrastructure détruite"

preprod:
	@export KUBECONFIG=$(HOME)/.kube/promox/config && k9s
#!/bin/bash
# Script pour mettre à jour l'inventory Ansible depuis les outputs Terraform

set -e

echo "📝 Mise à jour de l'inventory depuis Terraform..."
echo ""

# Charger le fichier .env pour récupérer K3S_TOKEN
if [ -f .env ]; then
  source .env
  echo "✅ Variables d'environnement chargées depuis .env"
else
  echo "⚠️  Fichier .env introuvable"
  echo ""
  echo "📝 Procédure manuelle:"
  echo "   1. Créer le fichier .env à la racine:"
  echo "      cp .env.example .env"
  echo "   2. Générer un token K3S:"
  echo "      openssl rand -hex 32"
  echo "   3. Ajouter dans .env:"
  echo "      K3S_TOKEN=<votre-token>"
  exit 1
fi

if [ -z "$K3S_TOKEN" ]; then
  echo "❌ K3S_TOKEN non défini dans .env"
  echo ""
  echo "📝 Procédure:"
  echo "   1. Éditer .env"
  echo "   2. Ajouter: K3S_TOKEN=\$(openssl rand -hex 32)"
  exit 1
fi

cd terraform/k3s-proxmox

# Vérifier que Terraform a été initialisé
if [ ! -d ".terraform" ]; then
  echo "❌ Terraform n'a pas été initialisé"
  echo ""
  echo "📝 Procédure:"
  echo "   cd terraform/k3s-proxmox"
  echo "   terraform init"
  exit 1
fi

# Récupérer les infos du cluster
echo "🔍 Récupération des IPs depuis Terraform..."
CLUSTER_INFO=$(terraform output -json k3s_cluster_info 2>/dev/null)

if [ -z "$CLUSTER_INFO" ]; then
  echo "❌ Impossible de récupérer les IPs depuis Terraform"
  echo ""
  echo "💡 Assurez-vous d'avoir appliqué Terraform avant:"
  echo "   cd terraform/k3s-proxmox"
  echo "   terraform apply"
  echo ""
  echo "📝 Procédure manuelle:"
  echo "   1. Récupérer les IPs:"
  echo "      terraform output k3s_cluster_info"
  echo "   2. Éditer l'inventory manuellement:"
  echo "      nano ansible/k3s-ansible/inventory.yml"
  exit 1
fi

# Extraire le master et les workers
MASTER_IP=$(echo "$CLUSTER_INFO" | jq -r '.master')
WORKER_IPS=$(echo "$CLUSTER_INFO" | jq -r '.workers[]')

if [ -z "$MASTER_IP" ] || [ "$MASTER_IP" = "null" ]; then
  echo "❌ Impossible de parser les IPs depuis l'output Terraform"
  echo ""
  echo "📝 Procédure manuelle:"
  echo "   1. Vérifier l'output Terraform:"
  echo "      terraform output k3s_cluster_info"
  echo "   2. Mettre à jour l'inventory manuellement"
  exit 1
fi

echo ""
echo "✅ IPs récupérées depuis Terraform:"
echo "   Master: $MASTER_IP"
echo "   Workers:"
echo "$WORKER_IPS" | while read -r worker; do
  echo "     - $worker"
done

cd ../../ansible/k3s-ansible

# Sauvegarde de l'ancien inventory
if [ -f inventory.yml ]; then
  cp inventory.yml inventory.yml.backup
  echo ""
  echo "📋 Backup de l'ancien inventory créé: inventory.yml.backup"
fi

# Génération du nouvel inventory
echo ""
echo "✍️  Génération du nouvel inventory..."

cat > inventory.yml <<EOF
---
k3s_cluster:
  children:
    server:
      hosts:
        $MASTER_IP:
    agent:
      hosts:
$(echo "$WORKER_IPS" | awk '{print "        " $1 ":"}')
  vars:
    ansible_port: 22
    ansible_user: debian
   
    k3s_version: v1.34.1+k3s1
    ansible_ssh_private_key_file: ~/.ssh/id_rsa_k3s
    ansible_user: debian
    ansible_become: true
  
    token: "{{ lookup('env', 'K3S_TOKEN') }}"
    api_endpoint: $MASTER_IP
EOF

echo "✅ Inventory mis à jour avec succès"
echo ""
echo "📄 Contenu de l'inventory:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat inventory.yml
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Prochaine étape:"
echo "   make accept-ssh"
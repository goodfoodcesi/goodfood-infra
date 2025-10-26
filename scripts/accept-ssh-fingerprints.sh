#!/bin/bash

set -e

INVENTORY_PATH="ansible/k3s-ansible/inventory.yml"

echo "🔐 Acceptation des fingerprints SSH..."
echo ""

# Vérifier que l'inventory existe
if [ ! -f "$INVENTORY_PATH" ]; then
  echo "❌ Fichier inventory introuvable: $INVENTORY_PATH"
  echo ""
  echo "💡 Assurez-vous d'avoir mis à jour l'inventory avant d'accepter les fingerprints."
  echo "   Exécutez: make update-inventory"
  exit 1
fi

echo "📋 Lecture de l'inventory: $INVENTORY_PATH"
MASTER_IP=$(grep -A 2 "server:" "$INVENTORY_PATH" | grep -E '^\s+[0-9]' | awk -F: '{print $1}' | xargs)
WORKER_IPS=$(grep -A 10 "agent:" "$INVENTORY_PATH" | grep -E '^\s+[0-9]' | awk -F: '{print $1}' | xargs)

if [ -z "$MASTER_IP" ]; then
  echo "❌ Impossible de lire les IPs depuis l'inventory"
  echo ""
  echo "📝 Procédure manuelle:"
  echo "   1. Vérifier le contenu de: $INVENTORY_PATH"
  echo "   2. Accepter les fingerprints manuellement:"
  echo "      ssh-keyscan -H <IP> >> ~/.ssh/known_hosts"
  exit 1
fi

echo ""
echo "✅ IPs détectées dans l'inventory:"
echo "   Master: $MASTER_IP"
echo "   Workers: $WORKER_IPS"
echo ""

echo "🔗 Connexion au master: $MASTER_IP"
ssh-keyscan -H "$MASTER_IP" >> ~/.ssh/known_hosts 2>/dev/null

# Accepter les fingerprints des workers
for worker in $WORKER_IPS; do
  echo "🔗 Connexion au worker: $worker"
  ssh-keyscan -H "$worker" >> ~/.ssh/known_hosts 2>/dev/null
done

echo ""
echo "✅ Fingerprints SSH acceptés pour toutes les VMs"
echo ""
echo "💡 Vous pouvez maintenant exécuter les playbooks Ansible sans erreur SSH."
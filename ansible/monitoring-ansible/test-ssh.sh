#!/bin/bash
# Script de test de connexion SSH pour Ansible

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Test de connexion SSH pour Ansible${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if inventory exists
if [ ! -f "inventory.ini" ]; then
    echo -e "${RED}❌ inventory.ini non trouvé${NC}"
    exit 1
fi

# Extract connection info from inventory
VM_IP=$(grep ansible_host inventory.ini | grep -v "^\[" | head -1 | awk -F'ansible_host=' '{print $2}' | awk '{print $1}')
VM_USER=$(grep ansible_user inventory.ini | grep -v "^\[" | head -1 | awk -F'ansible_user=' '{print $2}' | awk '{print $1}')
SSH_KEY=$(grep ansible_ssh_private_key_file inventory.ini | head -1 | awk -F'ansible_ssh_private_key_file=' '{print $2}' | awk '{print $1}')

# Expand tilde in SSH key path
SSH_KEY="${SSH_KEY/#\~/$HOME}"

echo -e "${YELLOW}Configuration détectée :${NC}"
echo "  IP          : $VM_IP"
echo "  Utilisateur : $VM_USER"
echo "  Clé SSH     : $SSH_KEY"
echo ""

# Test 1: Check if SSH key exists
echo -e "${YELLOW}[1/5] Vérification de la clé SSH...${NC}"
if [ -f "$SSH_KEY" ]; then
    echo -e "${GREEN}  ✓ Clé SSH trouvée${NC}"
    
    # Check permissions
    PERMS=$(stat -c "%a" "$SSH_KEY" 2>/dev/null || stat -f "%OLp" "$SSH_KEY" 2>/dev/null)
    if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
        echo -e "${GREEN}  ✓ Permissions correctes ($PERMS)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Permissions : $PERMS (devrait être 600)${NC}"
        echo -e "${YELLOW}    Correction : chmod 600 $SSH_KEY${NC}"
    fi
else
    echo -e "${RED}  ✗ Clé SSH non trouvée : $SSH_KEY${NC}"
    echo -e "${YELLOW}    Solutions :${NC}"
    echo "    1. Vérifie le chemin dans inventory.ini"
    echo "    2. Génère une nouvelle clé : ssh-keygen -t ed25519"
    exit 1
fi
echo ""

# Test 2: Check if host is reachable
echo -e "${YELLOW}[2/5] Test de connectivité réseau...${NC}"
if ping -c 1 -W 2 "$VM_IP" &> /dev/null; then
    echo -e "${GREEN}  ✓ Host accessible (ping OK)${NC}"
else
    echo -e "${RED}  ✗ Host non accessible${NC}"
    echo -e "${YELLOW}    Vérifie que l'IP est correcte : $VM_IP${NC}"
    exit 1
fi
echo ""

# Test 3: Check if SSH port is open
echo -e "${YELLOW}[3/5] Vérification du port SSH (22)...${NC}"
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$VM_IP/22" 2>/dev/null; then
    echo -e "${GREEN}  ✓ Port SSH 22 ouvert${NC}"
else
    echo -e "${RED}  ✗ Port SSH 22 non accessible${NC}"
    echo -e "${YELLOW}    Le serveur SSH est-il démarré ?${NC}"
    exit 1
fi
echo ""

# Test 4: Test SSH connection
echo -e "${YELLOW}[4/5] Test de connexion SSH...${NC}"
if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=5 "$VM_USER@$VM_IP" "echo 'SSH OK'" &> /dev/null; then
    echo -e "${GREEN}  ✓ Connexion SSH réussie${NC}"
else
    echo -e "${RED}  ✗ Connexion SSH échouée${NC}"
    echo -e "${YELLOW}    Solutions possibles :${NC}"
    echo "    1. Copie ta clé publique : ssh-copy-id -i ${SSH_KEY}.pub $VM_USER@$VM_IP"
    echo "    2. Vérifie que l'utilisateur existe : $VM_USER"
    echo "    3. Vérifie les logs SSH sur le serveur : journalctl -u ssh"
    echo ""
    echo -e "${YELLOW}    Test manuel :${NC}"
    echo "    ssh -i $SSH_KEY $VM_USER@$VM_IP"
    exit 1
fi
echo ""

# Test 5: Test Ansible ping
echo -e "${YELLOW}[5/5] Test Ansible ping...${NC}"
if ansible monitoring -m ping &> /dev/null; then
    echo -e "${GREEN}  ✓ Ansible ping réussi${NC}"
else
    echo -e "${RED}  ✗ Ansible ping échoué${NC}"
    echo -e "${YELLOW}    Essaie avec verbose : ansible monitoring -m ping -vvv${NC}"
    exit 1
fi
echo ""

# Success message
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   ✓ Tous les tests passés avec succès !${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}Tu peux maintenant lancer le déploiement :${NC}"
echo ""
echo -e "  ${YELLOW}./deploy.sh${NC}"
echo ""
echo -e "ou"
echo ""
echo -e "  ${YELLOW}ansible-playbook playbook.yml${NC}"
echo ""

# Optional: Show system info
echo -e "${BLUE}Informations système de la VM :${NC}"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VM_USER@$VM_IP" "echo '  OS       :' \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'\"' -f2); echo '  Hostname :' \$(hostname); echo '  Uptime   :' \$(uptime -p); echo '  CPU      :' \$(nproc) cores; echo '  RAM      :' \$(free -h | grep Mem | awk '{print \$2}'); echo '  Disk     :' \$(df -h / | tail -1 | awk '{print \$2}' | tr '\n' ' ') '/' \$(df -h / | tail -1 | awk '{print \$4}')"
echo ""

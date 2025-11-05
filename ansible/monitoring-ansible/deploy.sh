#!/bin/bash
# Quick deployment script for monitoring stack

set -e

echo "================================================"
echo "   Monitoring Stack Deployment Script"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}❌ Ansible n'est pas installé${NC}"
    echo "Installation: sudo apt install ansible -y"
    exit 1
fi

echo -e "${GREEN}✓ Ansible trouvé${NC}"

# Check if inventory exists
if [ ! -f "inventory.yaml" ] && [ ! -f "inventory.yml" ] && [ ! -f "inventory.ini" ]; then
    echo -e "${RED}❌ Aucun fichier d'inventaire trouvé${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Inventory trouvé${NC}"

# Option to run SSH test
echo ""
echo -e "${YELLOW}Veux-tu tester la connexion SSH d'abord ? (recommandé)${NC}"
read -p "Lancer le test SSH ? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "test-ssh.sh" ]; then
        ./test-ssh.sh || exit 1
    else
        echo -e "${YELLOW}⚠️  test-ssh.sh non trouvé, test manuel...${NC}"
        ansible monitoring -m ping || exit 1
    fi
else
    # Test connection without full script
    echo ""
    echo -e "${YELLOW}Test rapide de la connexion SSH...${NC}"
    if ansible monitoring -m ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connexion SSH OK${NC}"
    else
        echo -e "${RED}❌ Impossible de se connecter à la VM${NC}"
        echo "Vérifie l'IP et la clé SSH dans inventory.yaml ou inventory.ini"
        echo "Lance './test-ssh.sh' pour plus de détails"
        exit 1
    fi
fi

# Check if user wants to customize variables
echo ""
echo -e "${YELLOW}⚠️  As-tu personnalisé les variables dans vars/main.yml ?${NC}"
echo "  - grafana_admin_password"
echo "  - allowed_networks"
read -p "Continuer ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Édite vars/main.yml puis relance ce script"
    exit 0
fi

# Run playbook
echo ""
echo -e "${GREEN}🚀 Lancement du déploiement...${NC}"
echo ""

if ansible-playbook playbook.yml; then
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}   ✓ Déploiement réussi !${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo "Accès aux services :"
    
    # Get VM IP from ansible-inventory if available
    if command -v ansible-inventory &> /dev/null; then
        VM_IP=$(ansible-inventory --list | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
    else
        # Fallback: try to parse from inventory files
        if [ -f "inventory.yaml" ] || [ -f "inventory.yml" ]; then
            VM_IP=$(grep -oP '\d+\.\d+\.\d+\.\d+' inventory.y* | head -1 | cut -d':' -f2)
        elif [ -f "inventory.ini" ]; then
            VM_IP=$(grep -oP 'ansible_host=\K\d+\.\d+\.\d+\.\d+' inventory.ini | head -1)
        fi
    fi
    
    if [ -z "$VM_IP" ]; then
        VM_IP="<IP_DE_TA_VM>"
    fi
    
    echo ""
    echo -e "  Grafana:    ${GREEN}http://${VM_IP}:3000${NC}"
    echo -e "  Prometheus: ${GREEN}http://${VM_IP}:9090${NC}"
    echo -e "  Loki:       ${GREEN}http://${VM_IP}:3100${NC}"
    echo ""
    echo "Credentials Grafana :"
    echo "  User: admin"
    echo "  Password: (voir vars/main.yml)"
    echo ""
    echo -e "${YELLOW}Vérifie l'installation avec :${NC}"
    echo "  ansible-playbook verify.yml"
    echo ""
else
    echo ""
    echo -e "${RED}================================================${NC}"
    echo -e "${RED}   ❌ Échec du déploiement${NC}"
    echo -e "${RED}================================================${NC}"
    echo ""
    echo "Vérifie les logs ci-dessus pour plus d'infos"
    exit 1
fi

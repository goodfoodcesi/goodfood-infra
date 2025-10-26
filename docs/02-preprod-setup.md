# 🖥️ Setup Preprod - K3s Proxmox

Guide complet pour déployer l'environnement de preprod sur le cluster K3s Proxmox.

---

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- [x] **Accès Proxmox** (admin)
- [x] **Terraform installé** (`brew install terraform`)
- [x] **Ansible installé** (`brew install ansible`)
- [x] **kubectl installé** (`brew install kubectl`)
- [x] **jq installé** (`brew install jq`) - pour les scripts
- [x] **Clé SSH configurée** (`~/.ssh/id_rsa_k3s`)
- [x] **SOPS + Age configurés** (voir [README-SOPS.md](./README-SOPS.md))
- [x] **Fichier `.env` créé** (voir ci-dessous)

---

## 🏗️ Architecture

```
Proxmox
├── VM 1: k3s-master    (IP dynamique, ex: 192.168.1.182)
├── VM 2: k3s-worker-1  (IP dynamique, ex: 192.168.1.149)
├── VM 3: k3s-worker-2  (IP dynamique, ex: 192.168.1.15)
└── VM 4: k3s-worker-3  (IP dynamique, ex: 192.168.1.156)
```

**Total : 4 VMs** (1 master + 3 workers)

---

## ⚙️ Configuration Initiale

### 1️⃣ Créer le fichier `.env`

À la **racine du projet** :

```bash
# Copier le template
cp .env.example .env

# Éditer le fichier
nano .env
```

Contenu du `.env` :

```bash
# Token K3s (générer avec: openssl rand -hex 32)
K3S_TOKEN=votre-token-super-secret-ici
```

**Générer un token sécurisé :**
```bash
openssl rand -hex 32
```

⚠️ **Important :** Le fichier `.env` ne doit **JAMAIS** être versionné (déjà dans `.gitignore`).

---

### 2️⃣ Générer la clé SSH K3s

```bash
# Générer la clé
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_k3s -C "k3s-cluster" -N ""

# Vérifier
ls -la ~/.ssh/id_rsa_k3s*
```

---

### 3️⃣ Configurer les secrets Terraform (SOPS)

Voir le guide complet : [**README-SOPS.md**](./README-SOPS.md)

```bash
# Éditer les secrets Terraform
cd terraform/k3s-proxmox/
sops secrets.enc.yaml

# Ajouter vos valeurs Proxmox
```

---

## 🚀 Installation Complète

### Méthode 1 : Automatisée (Makefile) - Recommandé ⭐

#### Setup complet en une commande

```bash
# Depuis la racine du projet
make setup-all
```

Cette commande exécute automatiquement :
1. ✅ Création des VMs (Terraform)
2. ✅ Mise à jour de l'inventory
3. ✅ Acceptation des fingerprints SSH
4. ✅ Installation K3s + rsync
5. ✅ Installation ArgoCD
6. ✅ Déploiement des secrets
7. ✅ Déploiement des applications

**Durée totale : ~15-20 minutes**

---

#### OU étape par étape

```bash
# Phase 1 : Infrastructure
make setup-infra        # Créer les VMs avec Terraform

# Phase 2 : Configuration
make update-inventory   # Mettre à jour l'inventory Ansible
make accept-ssh         # Accepter les fingerprints SSH

# Phase 3 : K3s
make setup-k3s          # Installer K3s + rsync

# Phase 4 : ArgoCD
make setup-argocd       # Installer ArgoCD

# Phase 5 : Applications
make deploy-secrets     # Déployer les secrets
make deploy-apps        # Déployer les applications

# (Optionnel) Récupérer le kubeconfig pour K9s
make fetch-kubeconfig
```

---

### Méthode 2 : Manuelle (si les scripts ne fonctionnent pas)

Si les scripts automatiques échouent, voici la procédure manuelle complète.

---

#### PHASE 0 : Créer le Template Proxmox (une seule fois)

Cette étape n'est nécessaire qu'**une seule fois** lors du premier setup.

```bash
# 1. Se connecter au serveur Proxmox en SSH
ssh root@votre-serveur-proxmox

# 2. Créer le dossier de travail
mkdir -p /tmp/template-setup
cd /tmp/template-setup

# 3. Copier le script depuis votre machine locale
# (depuis votre Mac, dans un autre terminal)
scp terraform/k3s-proxmox/scripts-template-proxmox/setup-template.sh \
  root@votre-serveur-proxmox:/tmp/template-setup/

# 4. Revenir sur le serveur Proxmox et exécuter le script
bash setup-template.sh

# 5. Vérifier que le template est créé
qm list | grep debian
# Devrait afficher une VM template "debian-12-cloudinit"
```

**✅ Checkpoint :** Le template VM existe sur Proxmox

---

#### PHASE 1 : Infrastructure (Terraform)

```bash
# 1. Aller dans le dossier Terraform
cd terraform/k3s-proxmox/

# 2. Déchiffrer les secrets (temporairement)
sops -d secrets.enc.yaml > secrets.auto.tfvars

# 3. Initialiser Terraform
terraform init

# 4. Voir le plan
terraform plan

# 5. Créer les VMs
terraform apply -auto-approve

# 6. Noter les IPs affichées
terraform output k3s_cluster_info

# Exemple de sortie:
# k3s_cluster_info = {
#   "master" = "192.168.1.182"
#   "workers" = ["192.168.1.149", "192.168.1.15", "192.168.1.156"]
# }

# 7. IMPORTANT : Supprimer le fichier déchiffré
rm secrets.auto.tfvars

# 8. Revenir à la racine
cd ../..
```

**✅ Checkpoint :** 4 VMs sont créées sur Proxmox avec des IPs attribuées

---

#### PHASE 2 : Mise à jour de l'Inventory Ansible

```bash
# 1. Récupérer les IPs depuis Terraform
cd terraform/k3s-proxmox/
MASTER_IP=$(terraform output -json k3s_cluster_info | jq -r '.master')
WORKER_IPS=$(terraform output -json k3s_cluster_info | jq -r '.workers[]')

echo "Master IP: $MASTER_IP"
echo "Workers IPs:"
echo "$WORKER_IPS"

# 2. Charger le token depuis .env
cd ../..
source .env

# 3. Éditer l'inventory manuellement
nano ansible/k3s-ansible/inventory.yml
```

Mettez à jour le fichier avec les nouvelles IPs :

```yaml
---
k3s_cluster:
  children:
    server:
      hosts:
        192.168.1.182:  # ← Remplacer par votre MASTER_IP
    agent:
      hosts:
        192.168.1.149:  # ← Remplacer par vos WORKER_IPS
        192.168.1.15:
        192.168.1.156:
  vars:
    ansible_port: 22
    ansible_user: debian
   
    k3s_version: v1.34.1+k3s1
    ansible_ssh_private_key_file: ~/.ssh/id_rsa_k3s
    ansible_user: debian
    ansible_become: true
  
    token: "{{ lookup('env', 'K3S_TOKEN') }}"  # Lit depuis .env
    api_endpoint: 192.168.1.182  # ← Remplacer par votre MASTER_IP
```

**✅ Checkpoint :** L'inventory est à jour avec les bonnes IPs

---

#### PHASE 3 : Accepter les Fingerprints SSH

```bash
# Remplacer les IPs par les vôtres
MASTER_IP="192.168.1.182"
WORKER1_IP="192.168.1.149"
WORKER2_IP="192.168.1.15"
WORKER3_IP="192.168.1.156"

# Accepter le fingerprint de chaque VM
ssh-keyscan -H $MASTER_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $WORKER1_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $WORKER2_IP >> ~/.ssh/known_hosts
ssh-keyscan -H $WORKER3_IP >> ~/.ssh/known_hosts

# Vérifier l'accès SSH (optionnel)
ssh -i ~/.ssh/id_rsa_k3s debian@$MASTER_IP "echo 'SSH OK'"
```

**✅ Checkpoint :** SSH fonctionne vers toutes les VMs

---

#### PHASE 4 : Installation K3s

```bash
# 1. Charger le .env
source .env

# 2. Aller dans le dossier Ansible
cd ansible/k3s-ansible/

# 3. Installer K3s
ansible-playbook playbooks/site.yml -i inventory.yml

# 4. Installer rsync (nécessaire pour certaines opérations)
ansible-playbook playbooks/install-rsync.yml -i inventory.yml

# 5. Revenir à la racine
cd ../..
```

**⏳ Durée :** ~10 minutes

**✅ Checkpoint :** K3s est installé

**Vérifier l'installation :**
```bash
# Se connecter au master
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182

# Vérifier les nodes
sudo kubectl get nodes
# Devrait afficher 4 nodes Ready

# Se déconnecter
exit
```

---

#### PHASE 5 : Installation ArgoCD

```bash
# 1. Charger le .env
source .env

# 2. Aller dans le dossier Ansible
cd ansible/k3s-ansible/

# 3. Installer ArgoCD
ansible-playbook playbooks/install-argocd.yml -i inventory.yml

# 4. Revenir à la racine
cd ../..
```

**⏳ Durée :** ~5 minutes

**Récupérer le mot de passe ArgoCD :**
```bash
# Configurer kubectl pour pointer vers le cluster K3s
export KUBECONFIG=~/.kube/proxmox/config  # Si vous avez déjà fetch le kubeconfig

# Ou via SSH
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182 \
  "sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
```

**✅ Checkpoint :** ArgoCD est installé

---

#### PHASE 6 : Déploiement des Secrets

```bash
# 1. Charger le .env
source .env

# 2. Aller dans le dossier Ansible
cd ansible/k3s-ansible/

# 3. Déployer les secrets
ansible-playbook playbooks/create-secrets-preprod.yml -i inventory.yml

# 4. Revenir à la racine
cd ../..
```

**✅ Checkpoint :** Les secrets sont déployés

**Vérifier :**
```bash
# Via SSH
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182 \
  "sudo kubectl get secrets -n preprod"
```

---

#### PHASE 7 : Déploiement des Applications

```bash
# 1. Charger le .env
source .env

# 2. Aller dans le dossier Ansible
cd ansible/k3s-ansible/

# 3. Déployer les applications ArgoCD
ansible-playbook playbooks/deploy-argocd-app.yml -i inventory.yml

# 4. Revenir à la racine
cd ../..
```

**✅ Checkpoint :** Les applications sont déployées

---

#### PHASE 8 : Configuration DNS Locale

```bash
# Ajouter dans /etc/hosts (remplacer par l'IP de votre master)
sudo nano /etc/hosts

# Ajouter ces lignes:
192.168.1.182  argocd.goodfood.test
192.168.1.182  preprod.goodfood.test
```

---

#### PHASE 9 : Accès aux Applications

**ArgoCD :**
```bash
# Ouvrir ArgoCD
open http://argocd.goodfood.test

# Login:
# Username: admin
# Password: (récupéré en PHASE 5)
```

**Application Preprod :**
```bash
# Ouvrir l'application
open http://preprod.goodfood.test
```

**✅ Checkpoint :** Tout fonctionne ! 🎉

---

## 📥 (Optionnel) Récupérer le Kubeconfig pour K9s

### Via Makefile

```bash
make fetch-kubeconfig
```

### Manuellement

```bash
# 1. Aller dans Ansible
cd ansible/k3s-ansible/

# 2. Exécuter le playbook
ansible-playbook playbooks/fetch-kubeconfig.yml -i inventory.yml

# 3. Revenir à la racine
cd ../..

# 4. Utiliser le kubeconfig
export KUBECONFIG=~/.kube/proxmox/config

# 5. Vérifier
kubectl get nodes

# 6. Lancer K9s
k9s
```

---

## 🛠️ Commandes Utiles

### Commandes Make

```bash
make help              # Afficher l'aide
make setup-all         # Setup complet
make setup-infra       # Créer les VMs
make setup-k3s         # Installer K3s
make setup-argocd      # Installer ArgoCD
make deploy-secrets    # Déployer secrets
make deploy-apps       # Déployer apps
make destroy           # Détruire l'infrastructure
```

### Commandes kubectl

```bash
# Configurer le contexte K3s
export KUBECONFIG=~/.kube/proxmox/config

# Voir les nodes
kubectl get nodes

# Voir les pods
kubectl get pods -n preprod

# Voir les logs d'un pod
kubectl logs -f <pod-name> -n preprod

# Restart un deployment
kubectl rollout restart deployment/<deployment-name> -n preprod
```

### Commandes SSH

```bash
# Se connecter au master
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182

# Exécuter une commande à distance
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182 "sudo kubectl get nodes"

# Copier un fichier
scp -i ~/.ssh/id_rsa_k3s local-file.txt debian@192.168.1.182:/tmp/
```

---

## 🔄 Workflow de Mise à Jour

### Déployer une nouvelle version

1. **Push les changements dans Git**
   ```bash
   git add .
   git commit -m "feat: nouvelle feature"
   git push origin main
   ```

2. **ArgoCD détecte et synchronise automatiquement**
   - Aller sur http://argocd.goodfood.test
   - Vérifier l'état de synchronisation
   - Forcer un sync si nécessaire

### Mettre à jour les secrets

```bash
# 1. Éditer les secrets locaux (non versionnés)
nano kube/preprod/03-secrets/db-credentials-configmap.yaml
nano kube/preprod/03-secrets/github-registry-secret.yaml

# 2. Redéployer
make deploy-secrets

# Ou manuellement
cd ansible/k3s-ansible/
source ../.env
ansible-playbook playbooks/create-secrets-preprod.yml -i inventory.yml
```

---

## 🐛 Troubleshooting

### Problème : Terraform ne trouve pas les secrets

**Symptôme :**
```
Error: Failed to get the data key
```

**Solution :**
```bash
# Vérifier que SOPS fonctionne
cd terraform/k3s-proxmox/
sops -d secrets.enc.yaml

# Si erreur, vérifier votre configuration SOPS
# Voir: docs/README-SOPS.md
```

---

### Problème : Ansible ne peut pas se connecter

**Symptôme :**
```
Failed to connect to the host via ssh
```

**Solutions :**

1. **Vérifier les fingerprints SSH**
   ```bash
   make accept-ssh
   
   # Ou manuellement
   ssh-keyscan -H 192.168.1.182 >> ~/.ssh/known_hosts
   ```

2. **Vérifier la clé SSH**
   ```bash
   ls -la ~/.ssh/id_rsa_k3s
   ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182
   ```

3. **Vérifier l'inventory**
   ```bash
   cat ansible/k3s-ansible/inventory.yml
   # Les IPs sont-elles bonnes ?
   ```

---

### Problème : K3S_TOKEN non défini

**Symptôme :**
```
❌ Erreur: K3S_TOKEN non défini dans .env
```

**Solution :**
```bash
# 1. Vérifier que .env existe
ls -la .env

# 2. Vérifier le contenu
cat .env
# Devrait contenir: K3S_TOKEN=xxx

# 3. Générer un token si manquant
echo "K3S_TOKEN=$(openssl rand -hex 32)" >> .env

# 4. Charger le .env
source .env
echo $K3S_TOKEN  # Devrait afficher le token
```

---

### Problème : ArgoCD ne synchronise pas

**Solutions :**

1. **Forcer la synchronisation dans l'UI**
   - Aller sur http://argocd.goodfood.test
   - Cliquer sur l'application
   - Cliquer "SYNC" → "SYNCHRONIZE"

2. **Via CLI**
   ```bash
   # Installer argocd CLI
   brew install argocd
   
   # Login
   argocd login argocd.goodfood.test --username admin
   
   # Forcer sync
   argocd app sync goodfood-preprod --force
   ```

3. **Vérifier les logs**
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

---

### Problème : Les pods ne démarrent pas

**Diagnostics :**

```bash
# 1. Voir l'état des pods
kubectl get pods -n preprod

# 2. Describe un pod en erreur
kubectl describe pod <pod-name> -n preprod

# 3. Voir les logs
kubectl logs <pod-name> -n preprod

# 4. Vérifier les secrets
kubectl get secrets -n preprod

# 5. Vérifier les images
kubectl get pods -n preprod -o jsonpath='{.items[*].spec.containers[*].image}'
```

**Solutions courantes :**

- **ImagePullBackOff** : Vérifier les secrets de registry
  ```bash
  kubectl get secret ghcr-secret -n preprod -o yaml
  ```

- **CrashLoopBackOff** : Voir les logs du pod
  ```bash
  kubectl logs <pod-name> -n preprod --previous
  ```

---

### Problème : Script update-inventory ne fonctionne pas

**Solution manuelle :**

```bash
# 1. Récupérer les IPs depuis Terraform
cd terraform/k3s-proxmox/
terraform output -json k3s_cluster_info

# 2. Éditer l'inventory manuellement
nano ../../ansible/k3s-ansible/inventory.yml

# 3. Remplacer les IPs
# - Master dans la section "server:"
# - Workers dans la section "agent:"
```

---

### Problème : Script accept-ssh ne fonctionne pas

**Solution manuelle :**

```bash
# Accepter les fingerprints un par un
ssh-keyscan -H 192.168.1.182 >> ~/.ssh/known_hosts
ssh-keyscan -H 192.168.1.149 >> ~/.ssh/known_hosts
ssh-keyscan -H 192.168.1.15 >> ~/.ssh/known_hosts
ssh-keyscan -H 192.168.1.156 >> ~/.ssh/known_hosts

# Ou se connecter manuellement (accepter "yes")
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.182
# Tapez "yes" puis Ctrl+D pour déconnecter
```

---

## 🗑️ Détruire l'Infrastructure

### Via Makefile

```bash
make destroy
```

### Manuellement

```bash
cd terraform/k3s-proxmox/

# Déchiffrer les secrets
sops -d secrets.enc.yaml > secrets.auto.tfvars

# Détruire
terraform destroy

# Nettoyer
rm secrets.auto.tfvars
```

⚠️ **Attention :** Cette action est **irréversible** !

---

## 📚 Ressources

- [Guide SOPS](./README-SOPS.md) - Gestion des secrets
- [Guide Local Dev](./01-local-dev-setup.md) - Setup Minikube
- [Documentation K3s](https://docs.k3s.io/)
- [Documentation ArgoCD](https://argo-cd.readthedocs.io/)
- [Documentation Terraform Proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

---

## 🎯 Checklist Complète

- [ ] **Phase 0 : Setup initial**
  - [ ] Template Proxmox créé
  - [ ] .env créé avec K3S_TOKEN
  - [ ] Clé SSH générée (~/.ssh/id_rsa_k3s)
  - [ ] SOPS configuré

- [ ] **Phase 1 : Infrastructure**
  - [ ] Terraform apply réussi
  - [ ] 4 VMs créées sur Proxmox
  - [ ] IPs récupérées

- [ ] **Phase 2 : Configuration**
  - [ ] Inventory mis à jour avec les bonnes IPs
  - [ ] Fingerprints SSH acceptés

- [ ] **Phase 3 : K3s**
  - [ ] K3s installé
  - [ ] rsync installé
  - [ ] 4 nodes Ready

- [ ] **Phase 4 : ArgoCD**
  - [ ] ArgoCD installé
  - [ ] Password récupéré
  - [ ] UI accessible

- [ ] **Phase 5 : Applications**
  - [ ] Secrets déployés
  - [ ] Applications déployées
  - [ ] DNS configuré (/etc/hosts)
  - [ ] Applications accessibles

---

**Bon déploiement ! 🚀**
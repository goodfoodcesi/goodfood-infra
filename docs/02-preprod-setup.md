# 🖥️ Setup Preprod - K3s Proxmox

Guide complet pour déployer l'environnement de preprod sur le cluster K3s Proxmox.

---

## 📋 Prérequis

- [x] Accès Proxmox
- [x] Terraform installé
- [x] Ansible installé
- [x] Clé SSH configurée (`~/.ssh/id_rsa_k3s`)
- [x] Variables d'environnement configurées (`.env`)

---

## 🏗️ Architecture
```
Proxmox
├── VM 1: k3s-master (192.168.1.10)
├── VM 2: k3s-worker-1 (192.168.1.11)
└── VM 3: k3s-worker-2 (192.168.1.12)
```

---

## 🚀 Installation complète

### 1️⃣ Provisionner l'infrastructure (Terraform)
```bash
cd terraform/k3s-proxmox/

# Initialiser Terraform
terraform init

# Voir le plan
terraform plan

# Créer les VMs
terraform apply

# Noter les IPs affichées
# Output:
# master_ip = "192.168.1.10"
# worker_ips = ["192.168.1.11", "192.168.1.12"]
```

**⏳ Durée:** ~5 minutes

**✅ Checkpoint:** Les 3 VMs sont créées sur Proxmox

---

### 2️⃣ Installer K3s (Ansible)
```bash
cd ../../ansible/k3s-ansible/

# Charger les variables d'environnement
source .env

# Installer K3s sur le cluster
ansible-playbook playbooks/site.yml -i inventory.yml
```

**⏳ Durée:** ~10 minutes

**✅ Checkpoint:** K3s est installé

#### Vérifier l'installation
```bash
# Se connecter au master
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.10

# Vérifier les nodes
kubectl get nodes
# Devrait afficher 3 nodes Ready

# Se déconnecter
exit
```

---

### 3️⃣ Récupérer le kubeconfig
```bash
# Depuis ton Mac
scp -i ~/.ssh/id_rsa_k3s debian@192.168.1.10:/etc/rancher/k3s/k3s.yaml \
  ~/Documents/Projets/Good\ Food/Infra/remote-k3S-config-for-local/config

# Modifier l'IP dans le fichier
sed -i '' 's/127.0.0.1/192.168.1.10/g' \
  ~/Documents/Projets/Good\ Food/Infra/remote-k3S-config-for-local/config
```

#### Tester le kubeconfig
```bash
# Switcher vers K3s
eval $(make env-k3s)

# Vérifier
kubectl get nodes
# Devrait afficher les 3 nodes K3s

# Lancer k9s
make preprod
```

**✅ Checkpoint:** Tu vois le cluster K3s dans k9s

---

### 4️⃣ Créer les secrets
```bash
# Switcher vers K3s
eval $(make env-k3s)

# Créer les secrets
make secrets-preprod

# Vérifier
kubectl get secrets -n preprod
```

**✅ Checkpoint:** Les secrets existent dans le namespace preprod

---

### 5️⃣ Installer ArgoCD

#### Option A: ArgoCD dans Minikube (recommandé pour commencer)

ArgoCD tourne sur Minikube et gère à la fois dev et preprod.
```bash
# Switcher vers Minikube
eval $(make env-minikube)

# ArgoCD est déjà installé (si tu as suivi le guide local-dev)
# Sinon:
kubectl apply -k kube/argocd/install/

# Ajouter le cluster K3s dans ArgoCD
argocd cluster add default --name k3s-preprod \
  --kubeconfig ~/Documents/Projets/Good\ Food/Infra/remote-k3S-config-for-local/config
```

**Modifier goodfood-preprod.yaml:**
```yaml
# kube/argocd/applications/goodfood-preprod.yaml
spec:
  destination:
    name: k3s-preprod  # ← Nom du cluster ajouté
    namespace: preprod
```

---

#### Option B: ArgoCD sur K3s (plus propre, plus tard)
```bash
# Switcher vers K3s
eval $(make env-k3s)

# Installer ArgoCD sur K3s
kubectl apply -k kube/argocd/install/

# etc...
```

---

### 6️⃣ Déployer l'application
```bash
# Créer l'application ArgoCD preprod
kubectl apply -f kube/argocd/applications/goodfood-preprod.yaml

# Dans l'UI ArgoCD, SYNC l'app goodfood-preprod
```

**✅ Checkpoint:** L'application est déployée sur K3s

---

### 7️⃣ Configuration DNS locale
```bash
sudo nano /etc/hosts

# Ajouter:
192.168.1.10  preprod.goodfood.test
```

#### Accéder à l'application
```bash
# Avec NodePort (si configuré)
open http://preprod.goodfood.test:30080/bo

# Ou avec LoadBalancer (si MetalLB configuré)
open http://preprod.goodfood.test/bo
```

**✅ Checkpoint:** L'application s'affiche

---

## 🔄 Workflow de mise à jour

### Déployer via Ansible
```bash
cd ansible/k3s-ansible/
source .env

# Déployer l'application
ansible-playbook playbooks/deploy-goodfood.yml -i inventory.yml
```

### Déployer via ArgoCD (recommandé)

1. Push les changements dans Git
2. ArgoCD détecte automatiquement
3. Sync dans l'UI (ou auto-sync)

---

## 🛠️ Commandes utiles
```bash
# Switcher vers K3s
eval $(make env-k3s)

# Voir les pods
kubectl get pods -n preprod

# Logs
kubectl logs -f <pod-name> -n preprod

# Se connecter au master
ssh -i ~/.ssh/id_rsa_k3s debian@192.168.1.10

# Détruire l'infrastructure
cd terraform/k3s-proxmox/
terraform destroy
```

---

## 📞 Besoin d'aide ?

Voir [99-troubleshooting.md](./99-troubleshooting.md)
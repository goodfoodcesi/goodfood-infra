# 🍔 GoodFood Infrastructure

Infrastructure as Code pour le projet GoodFood - Gestion complète des environnements Dev, Preprod et Prod.

---

## 📚 Documentation

Toute la documentation se trouve dans le dossier [`docs/`](./docs/) :

- 🏠 [**Setup Local (Minikube)**](./docs/01-local-dev-setup.md) - Environnement de développement local
- 🖥️ [**Setup Preprod (K3s Proxmox)**](./docs/02-preprod-setup.md) - Cluster K3s sur Proxmox
- 🔐 [**Gestion des Secrets (SOPS)**](./docs/README-SOPS.md) - Chiffrement des secrets avec SOPS et Age
- 🔄 [**Guide ArgoCD**](./docs/03-argocd-guide.md) - GitOps et déploiement continu
- 🐛 [**Troubleshooting**](./docs/99-troubleshooting.md) - Résolution des problèmes courants

---

## 🌍 Environnements

| Environnement | Infrastructure | Namespace | URL |
|---------------|---------------|-----------|-----|
| **Dev** | Minikube (local) | `default` | http://dev.goodfood.test |
| **Preprod** | K3s Proxmox (4 VMs) | `preprod` | http://preprod.goodfood.test |
| **Prod** | *À venir* | `production` | https://goodfood.com |

---

## 🛠️ Stack Technique

- **Orchestration:** Kubernetes (Minikube / K3s)
- **GitOps:** ArgoCD
- **IaC:** Terraform (Proxmox)
- **Configuration Management:** Ansible
- **Secrets Management:** SOPS + Age
- **Container Registry:** GitHub Container Registry + Scaleway
- **Monitoring:** *À venir* (Grafana + Loki)

---

## 🚀 Quick Start

### 🏠 Dev Local (Minikube)

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

**[→ Guide complet Dev Local](./docs/01-local-dev-setup.md)**

---

### 🖥️ Preprod (K3s Proxmox)

```bash
# Setup complet automatisé
make setup-all

# Ou étape par étape
make setup-infra        # Terraform
make update-inventory   # Mise à jour inventory
make accept-ssh         # Fingerprints SSH
make setup-k3s          # Installation K3s
make setup-argocd       # Installation ArgoCD
make deploy-secrets     # Secrets
make deploy-apps        # Applications
```

**[→ Guide complet Preprod](./docs/02-preprod-setup.md)**

---

## 📂 Structure du Projet

```
goodfood-infra/
├── docs/                           # 📚 Documentation complète
│   ├── 01-local-dev-setup.md
│   ├── 02-preprod-setup.md
│   ├── README-SOPS.md
│   └── 99-troubleshooting.md
│
├── terraform/                      # 🏗️ Infrastructure as Code
│   └── k3s-proxmox/
│       ├── main.tf
│       ├── outputs.tf
│       └── secrets.enc.yaml        # Secrets chiffrés avec SOPS
│
├── ansible/                        # ⚙️ Configuration Management
│   └── k3s-ansible/
│       ├── inventory.yml           # Inventaire dynamique
│       └── playbooks/
│           ├── site.yml            # Install K3s
│           ├── install-argocd.yml
│           └── create-secrets-preprod.yml
│
├── kube/                           # ☸️ Manifests Kubernetes
│   ├── argocd/
│   │   ├── install/                # Installation ArgoCD
│   │   └── applications/           # Applications ArgoCD
│   ├── dev/                        # Manifests Dev
│   └── preprod/                    # Manifests Preprod
│       └── 03-secrets/             # ⚠️ NON VERSIONNÉ
│
├── scripts/                        # 🔧 Scripts d'automatisation
│   ├── accept-ssh-fingerprints.sh
│   └── update-inventory-from-terraform.sh
│
├── .env                            # ⚠️ NON VERSIONNÉ - Variables d'environnement
├── .env.example                    # Template pour .env
├── Makefile                        # 🤖 Automatisation des tâches
└── README.md                       # 📖 Ce fichier
```

---

## 🔐 Configuration Initiale

### 1️⃣ Créer le fichier `.env`

```bash
# Copier le template
cp .env.example .env

# Éditer et remplir les valeurs
nano .env
```

Le fichier `.env` doit contenir :
```bash
K3S_TOKEN=votre-token-genere
```

**Générer un token sécurisé :**
```bash
openssl rand -hex 32
```

### 2️⃣ Configurer SOPS (pour les secrets Terraform)

Voir le guide complet : [**docs/README-SOPS.md**](./docs/README-SOPS.md)

```bash
# Générer une clé Age
age-keygen -o ~/.config/sops/age/keys.txt

# Configurer SOPS
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: secrets\.enc\.yaml$
    age: "votre-clé-publique-age"
EOF
```

### 3️⃣ Générer la clé SSH pour K3s

```bash
# Générer la clé
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_k3s -C "k3s-cluster"

# Vérifier
ls -la ~/.ssh/id_rsa_k3s*
```

---

## 🎯 Commandes Make Principales

### Dev Local (Minikube)
```bash
make dev              # Lancer k9s sur Minikube
make secrets-dev      # Créer les secrets dev
```

### Preprod (K3s Proxmox)
```bash
make help             # Afficher toutes les commandes
make setup-all        # Setup complet (infra → apps)
make setup-infra      # Créer les VMs Terraform
make setup-k3s        # Installer K3s
make setup-argocd     # Installer ArgoCD
make deploy-secrets   # Déployer les secrets
make deploy-apps      # Déployer les applications
make destroy          # Détruire l'infrastructure
```

### Gestion des secrets
```bash
make sops-edit        # Éditer les secrets Terraform
```

---

## 🔄 Workflow de Développement

### 1. Développement local (Minikube)
```bash
# Travailler sur Minikube
minikube start && minikube tunnel
make dev  # k9s
```

### 2. Push sur Git
```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main
```

### 3. Déploiement automatique (ArgoCD)
- ArgoCD détecte les changements
- Synchronisation automatique vers preprod
- Vérification dans l'UI ArgoCD

---

## 🐛 Troubleshooting

En cas de problème, consultez :
- [**Guide de dépannage complet**](./docs/99-troubleshooting.md)
- [**Guide Preprod**](./docs/02-preprod-setup.md#-troubleshooting) - Section troubleshooting

### Problèmes courants

**Terraform ne trouve pas les secrets**
```bash
# Vérifier que SOPS est configuré
sops -d terraform/k3s-proxmox/secrets.enc.yaml
```

**Ansible ne peut pas se connecter**
```bash
# Accepter les fingerprints SSH
make accept-ssh

# Ou manuellement
ssh-keyscan -H 192.168.1.182 >> ~/.ssh/known_hosts
```

**ArgoCD ne synchronise pas**
```bash
# Forcer la synchronisation
argocd app sync goodfood-preprod --force
```

---

## 📞 Support

- 📖 Documentation : [`docs/`](./docs/)
- 🐛 Issues : Créer une issue GitHub
- 💬 Questions : Contacter l'équipe infra

---

## 🔒 Sécurité

⚠️ **Fichiers sensibles (NON versionnés) :**
- `.env` - Variables d'environnement
- `kube/preprod/03-secrets/*` - Secrets Kubernetes
- `~/.config/sops/age/keys.txt` - Clé Age privée
- `ansible/k3s-ansible/inventory.yml.backup` - Backups

✅ **Fichiers versionnés (chiffrés) :**
- `terraform/k3s-proxmox/secrets.enc.yaml` - Chiffré avec SOPS
- `.sops.yaml` - Configuration SOPS
- `.env.example` - Template (sans valeurs sensibles)

---

## 📝 License

Projet privé - GoodFood © 2025

---

## 🙏 Contributions

1. Créer une branche : `git checkout -b feature/ma-feature`
2. Commit : `git commit -m "feat: description"`
3. Push : `git push origin feature/ma-feature`
4. Créer une Pull Request

---

**Bon déploiement ! 🚀**
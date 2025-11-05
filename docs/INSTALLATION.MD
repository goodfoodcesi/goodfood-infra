# 📦 Package de Documentation et Scripts - GoodFood Infra

Tous les fichiers ont été créés avec succès ! 🎉

---

## 📂 Fichiers Créés

### 1. Documentation

| Fichier | Destination | Description |
|---------|-------------|-------------|
| `README.md` | Racine du projet | README principal avec quick start |
| `docs/README-SOPS.md` | `docs/` | Guide complet SOPS et Age |
| `docs/02-preprod-setup.md` | `docs/` | Guide setup preprod avec procédures manuelles |

### 2. Scripts

| Fichier | Destination | Description |
|---------|-------------|-------------|
| `scripts/accept-ssh-fingerprints.sh` | `scripts/` | Accepte les fingerprints SSH automatiquement |
| `scripts/update-inventory-from-terraform.sh` | `scripts/` | Met à jour l'inventory depuis Terraform |

### 3. Configuration

| Fichier | Destination | Description |
|---------|-------------|-------------|
| `.env.example` | Racine du projet | Template pour le fichier .env |
| `ansible-k3s-ansible-inventory.yml.example` | `ansible/k3s-ansible/` (comme exemple) | Exemple d'inventory |

---

## 🚀 Installation Rapide

### 1️⃣ Copier les fichiers

```bash
# Depuis le dossier où vous avez téléchargé les fichiers

# Documentation
cp README.md /chemin/vers/goodfood-infra/
cp docs/README-SOPS.md /chemin/vers/goodfood-infra/docs/
cp docs/02-preprod-setup.md /chemin/vers/goodfood-infra/docs/

# Scripts
cp scripts/accept-ssh-fingerprints.sh /chemin/vers/goodfood-infra/scripts/
cp scripts/update-inventory-from-terraform.sh /chemin/vers/goodfood-infra/scripts/

# Configuration
cp .env.example /chemin/vers/goodfood-infra/
```

### 2️⃣ Rendre les scripts exécutables

```bash
cd /chemin/vers/goodfood-infra/

chmod +x scripts/accept-ssh-fingerprints.sh
chmod +x scripts/update-inventory-from-terraform.sh
```

### 3️⃣ Créer le fichier .env

```bash
cd /chemin/vers/goodfood-infra/

# Copier le template
cp .env.example .env

# Générer un token
openssl rand -hex 32

# Éditer et ajouter le token
nano .env
# Ajouter: K3S_TOKEN=<le-token-généré>
```

### 4️⃣ Vérifier que tout est en place

```bash
# Documentation
ls -la docs/README-SOPS.md
ls -la docs/02-preprod-setup.md

# Scripts
ls -la scripts/accept-ssh-fingerprints.sh
ls -la scripts/update-inventory-from-terraform.sh

# Configuration
ls -la .env
```

---

## ✅ Checklist de Vérification

- [ ] `README.md` à la racine
- [ ] `docs/README-SOPS.md` dans le dossier docs
- [ ] `docs/02-preprod-setup.md` dans le dossier docs
- [ ] `scripts/accept-ssh-fingerprints.sh` dans scripts/ (exécutable)
- [ ] `scripts/update-inventory-from-terraform.sh` dans scripts/ (exécutable)
- [ ] `.env` créé et configuré avec K3S_TOKEN
- [ ] `.gitignore` contient `.env` (pour ne pas le versionner)

---

## 🎯 Prochaines Étapes

1. **Lire la documentation**
   ```bash
   # Commencez par le README principal
   cat README.md
   
   # Puis le guide preprod
   cat docs/02-preprod-setup.md
   ```

2. **Configurer SOPS** (si vous utilisez Terraform)
   ```bash
   # Suivez le guide
   cat docs/README-SOPS.md
   ```

3. **Tester le setup preprod**
   ```bash
   # Avec le Makefile
   make help
   make setup-all
   
   # Ou manuellement en suivant docs/02-preprod-setup.md
   ```

---

## 📚 Commandes Utiles

```bash
# Afficher l'aide du Makefile
make help

# Setup complet
make setup-all

# Mettre à jour l'inventory
make update-inventory

# Accepter les fingerprints SSH
make accept-ssh

# Installer K3s
make setup-k3s

# Installer ArgoCD
make setup-argocd

# Déployer les secrets et apps
make deploy-secrets
make deploy-apps
```

---

## 🐛 En Cas de Problème

Consultez la section **Troubleshooting** dans :
- `docs/02-preprod-setup.md` (section complète avec solutions)
- Chaque script affiche des messages d'erreur avec les procédures manuelles

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez la section Troubleshooting du guide preprod
2. Vérifiez que tous les prérequis sont installés
3. Essayez les procédures manuelles si les scripts échouent
4. Consultez les logs Ansible/Terraform pour plus de détails

---

**Bonne documentation et bon déploiement ! 🚀**
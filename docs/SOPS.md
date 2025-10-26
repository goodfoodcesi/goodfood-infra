# 🔐 Gestion Sécurisée des Secrets avec SOPS et Age

Ce guide explique comment gérer les secrets Terraform de manière sécurisée en utilisant **SOPS** (Secrets OPerationS) et **Age** pour le chiffrement.

---

## 🧠 Principe Général

**Problème :** Les fichiers Terraform ne doivent **jamais** contenir de secrets en clair (tokens, passwords, clés API, etc.).

**Solution :** 
- Chiffrer les secrets avec **SOPS + Age**
- Les stocker dans Git (chiffrés)
- Les déchiffrer automatiquement lors du `terraform apply`

---

## ⚙️ Installation

### macOS
```bash
brew install sops age terraform
```

### Linux
```bash
# SOPS
wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64
sudo mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops

# Age
brew install age  # ou depuis https://github.com/FiloSottile/age
```

### Vérification
```bash
sops --version
age --version
terraform --version
```

---

## 🔑 Configuration Initiale

### 1️⃣ Générer une Clé Age

```bash
# Créer le dossier
mkdir -p ~/.config/sops/age

# Générer la clé
age-keygen -o ~/.config/sops/age/keys.txt

# Afficher la clé publique
cat ~/.config/sops/age/keys.txt | grep "public key:"
# Output: public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**⚠️ Important :**
- La clé **privée** reste sur votre machine (`~/.config/sops/age/keys.txt`)
- La clé **publique** est utilisée dans `.sops.yaml` (à versionner)

### 2️⃣ Configurer SOPS

Créez le fichier `.sops.yaml` à la racine du projet :

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets\.enc\.yaml$
    age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # Votre clé publique
```

**Remplacez** `age1xxx...` par votre **vraie clé publique** !

---

## 📝 Utilisation

### Créer un fichier de secrets

#### 1️⃣ Créer le fichier chiffré

```bash
cd terraform/k3s-proxmox/

# Créer et éditer le fichier (ouvrira votre éditeur)
sops secrets.enc.yaml
```

#### 2️⃣ Ajouter vos secrets

Dans l'éditeur, ajoutez vos valeurs :

```yaml
# secrets.enc.yaml
proxmox_api_url: "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id: "terraform@pam!token"
proxmox_api_token_secret: "votre-secret-token-ici"
ssh_private_key_path: "~/.ssh/id_rsa_k3s"
```

Sauvegardez et fermez l'éditeur. **SOPS chiffre automatiquement le fichier !**

#### 3️⃣ Vérifier le chiffrement

```bash
# Le fichier est maintenant chiffré
cat secrets.enc.yaml
# Vous verrez du contenu chiffré, pas vos secrets en clair
```

---

### Éditer un fichier de secrets existant

```bash
cd terraform/k3s-proxmox/

# SOPS déchiffre automatiquement pour l'édition
sops secrets.enc.yaml

# Modifiez, sauvegardez → rechiffré automatiquement
```

---

### Lire un fichier de secrets (déchiffré)

```bash
# Afficher en clair (pour debug)
sops -d terraform/k3s-proxmox/secrets.enc.yaml
```

---

## 🔧 Intégration avec Terraform

### Configuration Terraform

Dans votre `main.tf` ou `variables.tf` :

```hcl
# variables.tf
variable "proxmox_api_url" {
  type        = string
  description = "URL de l'API Proxmox"
  sensitive   = true
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Token ID Proxmox"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Token Secret Proxmox"
  sensitive   = true
}
```

### Utilisation avec le Provider

```hcl
# main.tf
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure = true
}
```

---

## 🚀 Déploiement avec Secrets

### Méthode 1 : Via le Makefile (Recommandé)

Le `Makefile` gère automatiquement le déchiffrement :

```bash
# Le Makefile déchiffre automatiquement secrets.enc.yaml
make setup-infra
```

Le Makefile contient (exemple) :

```makefile
setup-infra:
	cd terraform/k3s-proxmox && \
	sops -d secrets.enc.yaml > secrets.auto.tfvars && \
	terraform init && \
	terraform apply && \
	rm secrets.auto.tfvars
```

### Méthode 2 : Manuellement

```bash
cd terraform/k3s-proxmox/

# 1. Déchiffrer temporairement
sops -d secrets.enc.yaml > secrets.auto.tfvars

# 2. Appliquer Terraform
terraform apply

# 3. IMPORTANT : Supprimer le fichier déchiffré
rm secrets.auto.tfvars
```

---

## 🔒 Bonnes Pratiques

### ✅ À FAIRE

1. **Versionner le fichier chiffré**
   ```bash
   git add terraform/k3s-proxmox/secrets.enc.yaml
   git commit -m "chore: update secrets"
   ```

2. **Versionner `.sops.yaml`**
   ```bash
   git add .sops.yaml
   git commit -m "chore: add SOPS config"
   ```

3. **Sauvegarder votre clé Age privée**
   - Faire une backup de `~/.config/sops/age/keys.txt`
   - La stocker dans un gestionnaire de mots de passe
   - **Ne JAMAIS la versionner !**

4. **Utiliser des noms explicites**
   ```yaml
   # ✅ Bien
   proxmox_api_token_secret: "xxx"
   
   # ❌ Mal
   secret1: "xxx"
   ```

### ❌ À NE PAS FAIRE

1. **Ne JAMAIS versionner les fichiers déchiffrés**
   ```bash
   # Ajouter dans .gitignore
   secrets.auto.tfvars
   secrets.tfvars
   *.auto.tfvars
   ```

2. **Ne JAMAIS versionner la clé privée Age**
   ```bash
   # La clé privée reste sur votre machine
   ~/.config/sops/age/keys.txt  # ← NE JAMAIS partager
   ```

3. **Ne JAMAIS commit de secrets en clair**
   ```bash
   # ❌ Mal
   variable "password" {
     default = "monmotdepasse123"  # NE JAMAIS FAIRE ÇA
   }
   ```

---

## 🔄 Workflow en Équipe

### Partage de Secrets

#### Option 1 : Partage de la clé Age (simple mais moins sécurisé)

1. Personne A génère la clé et configure SOPS
2. Personne A partage **la clé privée** de manière sécurisée (1Password, Bitwarden, etc.)
3. Personne B place la clé dans `~/.config/sops/age/keys.txt`
4. Les deux peuvent déchiffrer les secrets

#### Option 2 : Multiples clés Age (recommandé)

Configurer SOPS pour accepter plusieurs clés :

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets\.enc\.yaml$
    age: >-
      age1personne1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
      age1personne2xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx,
      age1personne3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Chacun peut déchiffrer avec sa propre clé !

---

## 🐛 Troubleshooting

### Erreur : `Failed to get the data key`

**Cause :** SOPS ne trouve pas votre clé privée Age

**Solution :**
```bash
# Vérifier que la clé existe
ls -la ~/.config/sops/age/keys.txt

# Vérifier que SOPS la détecte
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
sops -d secrets.enc.yaml
```

---

### Erreur : `no matching creation rules found`

**Cause :** Le fichier ne correspond pas au pattern dans `.sops.yaml`

**Solution :**
```bash
# Vérifier le nom du fichier
# Il doit correspondre au pattern dans .sops.yaml

# Par exemple, si .sops.yaml dit:
# path_regex: secrets\.enc\.yaml$
# Le fichier DOIT s'appeler: secrets.enc.yaml
```

---

### Erreur : `MAC mismatch`

**Cause :** Le fichier a été modifié sans SOPS

**Solution :**
```bash
# Ne jamais éditer secrets.enc.yaml directement !
# Toujours utiliser:
sops secrets.enc.yaml
```

---

### Terraform ne trouve pas les secrets

**Solution :**
```bash
# Vérifier que le déchiffrement fonctionne
cd terraform/k3s-proxmox/
sops -d secrets.enc.yaml

# Si ça affiche les secrets → OK
# Si erreur → voir troubleshooting ci-dessus
```

---

## 📚 Ressources

- [Documentation officielle SOPS](https://github.com/mozilla/sops)
- [Documentation Age](https://github.com/FiloSottile/age)
- [SOPS with Terraform (article)](https://blog.gruntwork.io/a-comprehensive-guide-to-managing-secrets-in-your-terraform-code-477d6d5ef1f9)

---

## 🎯 Résumé Rapide

```bash
# 1. Installer
brew install sops age

# 2. Générer clé Age
age-keygen -o ~/.config/sops/age/keys.txt

# 3. Configurer SOPS (.sops.yaml)
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: secrets\.enc\.yaml$
    age: $(cat ~/.config/sops/age/keys.txt | grep "public key:" | cut -d: -f2 | xargs)
EOF

# 4. Créer/éditer secrets
sops terraform/k3s-proxmox/secrets.enc.yaml

# 5. Utiliser avec Terraform
make setup-infra  # ou terraform apply manuellement

# 6. Versionner (fichier chiffré uniquement)
git add terraform/k3s-proxmox/secrets.enc.yaml .sops.yaml
git commit -m "chore: update secrets"
```

---

**Sécurité garantie ! 🔒**
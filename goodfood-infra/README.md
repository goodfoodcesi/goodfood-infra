# 🔐 Gestion sécurisée des secrets Terraform avec SOPS et Age

Ce projet utilise **SOPS** (Mozilla) et **Age** pour chiffrer les secrets sensibles utilisés par Terraform (ex : token Proxmox, chemin de clé SSH, mots de passe, etc.).

Grâce au **Makefile**, le chiffrement et le déchiffrement sont simples et automatisés, tout en gardant les secrets hors du dépôt Git.

---

## 🧠 Principe général

Terraform ne doit **jamais contenir de secrets en clair** dans les fichiers `.tf` ou `.tfvars`.

On utilise donc :
- un fichier `secrets.tfvars` (ou `secrets.auto.tfvars`)
- chiffré avec **SOPS + Age**
- temporairement déchiffré lors du `terraform apply` via le **Makefile**

---

## ⚙️ Installation

### 1️⃣ Installer les dépendances

#### macOS
```bash
brew install sops age terraform
```

---

Pour ajouter des secret avec sops:
```bash
sops secrets.enc.yaml 
```

avec cette manière de faire terraform est capable de dechiffrer avec sops pour récupéer les information tout seul
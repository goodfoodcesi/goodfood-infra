# 🏠 Setup Local - Minikube (Dev)

Guide complet pour déployer l'environnement de dev en local avec Minikube.

---

## 📋 Prérequis

- [x] Docker Desktop installé et démarré
- [x] Minikube installé (`brew install minikube`)
- [x] kubectl installé (`brew install kubectl`)
- [x] k9s installé (`brew install k9s`) - optionnel mais recommandé
- [x] Accès aux repos GitHub goodfoodcesi

---

## 🚀 Installation complète

### 1️⃣ Démarrer Minikube
```bash
# Démarrer le cluster
minikube start

# Vérifier
minikube status
kubectl get nodes

# Dans un AUTRE terminal, lancer le tunnel (ne pas fermer)
minikube tunnel
```

**✅ Checkpoint:** `minikube status` affiche "Running"

---

### 2️⃣ Configuration

#### /etc/hosts
```bash
sudo nano /etc/hosts

# Ajouter ces lignes:
127.0.0.1  dev.goodfood.test
127.0.0.1  argocd.goodfood.test
```

#### Contexte kubectl
```bash
# S'assurer d'être sur Minikube
kubectl config use-context minikube

# Vérifier
kubectl config current-context
# Output attendu: minikube
```

---

### 3️⃣ Créer les secrets
```bash
# Depuis la racine du repo
cd ~/Documents/Projets/goodfood-infra

# Créer les secrets
make secrets-dev

# Vérifier
kubectl get secrets -n default
# Devrait afficher: ghcr-secret, scw-secret
```

**✅ Checkpoint:** Les secrets existent

---

### 4️⃣ Installer ArgoCD
```bash
# Installer ArgoCD
kubectl apply -k kube/argocd/install/

# Attendre que tous les pods soient Running (1-2 min)
kubectl get pods -n argocd -w
# Ctrl+C quand tous sont Running
```

#### Récupérer le mot de passe admin
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Noter le mot de passe
```

#### Accéder à l'UI ArgoCD
```bash
# Via port-forward (tunnel Minikube parfois instable)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Ouvrir
open https://localhost:8080

# Login:
# Username: admin
# Password: (celui récupéré ci-dessus)
```

**✅ Checkpoint:** UI ArgoCD accessible

---

### 5️⃣ Déployer l'application
```bash
# Créer l'application ArgoCD
kubectl apply -f kube/argocd/applications/goodfood-dev.yaml

# Vérifier
kubectl get applications -n argocd
```

#### Synchroniser dans l'UI

1. Aller sur https://localhost:8080
2. Cliquer sur l'application `goodfood-dev`
3. Cliquer sur **"SYNC"**
4. Cliquer sur **"SYNCHRONIZE"**
5. Observer le déploiement ! 🎉

**✅ Checkpoint:** Tous les pods sont verts dans ArgoCD

---

### 6️⃣ Vérifier le déploiement
```bash
# Voir les pods
kubectl get pods -n default

# Voir les services
kubectl get svc -n default

# Lancer k9s pour explorer
make dev
# ou: k9s
```

#### Accéder à l'application
```bash
open http://dev.goodfood.test/bo
```

**✅ Checkpoint:** L'application s'affiche

---

## 🔄 Workflow quotidien

### Démarrer l'environnement
```bash
# Terminal 1: Démarrer Minikube
minikube start
minikube tunnel  # Laisser tourner

# Terminal 2: Lancer k9s
make dev
```

### Déployer une nouvelle version

Voir [05-deploy-new-version.md](./05-deploy-new-version.md)

### Arrêter l'environnement
```bash
# Arrêter Minikube (garde l'état)
minikube stop

# Ou supprimer complètement
minikube delete
```

---

## 🛠️ Commandes utiles
```bash
# Switcher vers Minikube
kubectl config use-context minikube

# Voir les logs d'un pod
kubectl logs -f <pod-name> -n default

# Restart un deployment
kubectl rollout restart deployment/back-office -n default

# Port-forward vers un service
kubectl port-forward svc/back-office -n default 3000:80

# Describe un pod
kubectl describe pod <pod-name> -n default
```

---

## 📞 Besoin d'aide ?

Voir [99-troubleshooting.md](./99-troubleshooting.md)
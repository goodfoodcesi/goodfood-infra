# Monitoring Stack - Grafana + Prometheus + Loki

Stack de monitoring complet pour récupérer les métriques et logs depuis un cluster Kubernetes vers une VM dédiée.

## 📋 Prérequis

### Sur la machine de contrôle (là où tu lances Ansible)
```bash
# Installer Ansible
sudo apt update
sudo apt install ansible -y

# Vérifier la version
ansible --version  # Minimum 2.10+
```

### Sur la VM cible (Debian 12)
- SSH activé
- Utilisateur avec droits sudo
- Python3 installé
- Au minimum 2 CPU, 4 GB RAM, 50 GB disque

## 🚀 Installation rapide

### 1. Configuration

Éditer `inventory.ini` avec l'IP de ta VM :
```ini
[monitoring]
monitoring-vm ansible_host=192.168.1.100 ansible_user=debian
```

### 2. Personnaliser les variables

Éditer `vars/main.yml` :
```yaml
# Change le mot de passe Grafana !
grafana_admin_password: "TonMotDePasseSecurisé"

# Ajuste la rétention si besoin
prometheus_retention_time: "15d"  # Rétention des métriques
loki_retention_period: "168h"     # Rétention des logs (7 jours)

# Sécurité réseau
allowed_networks:
  - "192.168.1.0/24"  # Ton réseau local uniquement
```

### 3. Tester la connexion

```bash
ansible monitoring -m ping
```

### 4. Lancer le déploiement

```bash
ansible-playbook playbook.yml
```

Le déploiement prend environ 5-10 minutes.

## 🎯 Accès aux services

Après le déploiement, tu pourras accéder à :

| Service | URL | Credentials |
|---------|-----|-------------|
| **Grafana** | http://IP_VM:3000 | admin / (ton mot de passe) |
| **Prometheus** | http://IP_VM:9090 | Pas d'auth |
| **Loki** | http://IP_VM:3100 | Pas d'auth (API seulement) |

## 📊 Vérification de l'installation

### Vérifier les services
```bash
ansible monitoring -m shell -a "systemctl status prometheus grafana-server loki"
```

### Vérifier les ports
```bash
ansible monitoring -m shell -a "ss -tlnp | grep -E '3000|9090|3100'"
```

### Tester Prometheus
```bash
curl http://IP_VM:9090/-/healthy
curl http://IP_VM:9090/api/v1/targets
```

### Tester Loki
```bash
curl http://IP_VM:3100/ready
```

## 🔧 Configuration Kubernetes (Prochaine étape)

Pour récupérer les métriques et logs de Kubernetes, tu devras :

### Dans Kubernetes :
1. **Promtail** (DaemonSet) → Envoie les logs à Loki
2. **kube-state-metrics** → Expose les métriques K8s
3. **node-exporter** → Métriques des nodes

### Configuration Prometheus pour Kubernetes

Ajouter dans `/etc/prometheus/prometheus.yml` (via Ansible ou manuellement) :

```yaml
scrape_configs:
  - job_name: 'kubernetes-nodes'
    static_configs:
      - targets:
        - 'k8s-node-1:9100'
        - 'k8s-node-2:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
        
  - job_name: 'kube-state-metrics'
    static_configs:
      - targets: ['k8s-node-1:8080']
```

## 📁 Structure du projet

```
monitoring-stack/
├── ansible.cfg              # Configuration Ansible
├── inventory.ini            # Inventaire des serveurs
├── playbook.yml            # Playbook principal
├── vars/
│   └── main.yml            # Variables globales
└── roles/
    ├── prometheus/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── templates/
    │   │   ├── prometheus.yml.j2
    │   │   └── prometheus.service.j2
    │   └── handlers/
    │       └── main.yml
    ├── loki/
    │   ├── tasks/
    │   │   └── main.yml
    │   ├── templates/
    │   │   ├── loki-config.yml.j2
    │   │   └── loki.service.j2
    │   └── handlers/
    │       └── main.yml
    └── grafana/
        ├── tasks/
        │   └── main.yml
        ├── templates/
        │   ├── grafana.ini.j2
        │   ├── datasource-prometheus.yml.j2
        │   ├── datasource-loki.yml.j2
        │   └── dashboard-provider.yml.j2
        └── handlers/
            └── main.yml
```

## 🔄 Opérations courantes

### Redémarrer un service
```bash
ansible monitoring -m systemd -a "name=prometheus state=restarted" --become
ansible monitoring -m systemd -a "name=loki state=restarted" --become
ansible monitoring -m systemd -a "name=grafana-server state=restarted" --become
```

### Voir les logs
```bash
ansible monitoring -m shell -a "journalctl -u prometheus -n 50 --no-pager"
ansible monitoring -m shell -a "journalctl -u loki -n 50 --no-pager"
ansible monitoring -m shell -a "journalctl -u grafana-server -n 50 --no-pager"
```

### Mettre à jour la configuration Prometheus
```bash
# Éditer roles/prometheus/templates/prometheus.yml.j2
# Puis relancer :
ansible-playbook playbook.yml --tags prometheus
```

### Recharger la config Prometheus sans redémarrage
```bash
ansible monitoring -m shell -a "curl -X POST http://localhost:9090/-/reload" --become
```

## 🛡️ Sécurité

### Recommandations :
1. **Change le mot de passe Grafana** immédiatement dans `vars/main.yml`
2. **Limite l'accès réseau** dans les variables `allowed_networks`
3. **Active HTTPS** avec un reverse proxy (Nginx/Traefik)
4. **Configure le firewall** sur la VM :
```bash
# UFW exemple
ufw allow from 192.168.1.0/24 to any port 3000
ufw allow from 192.168.1.0/24 to any port 9090
ufw allow from 192.168.1.0/24 to any port 3100
```

## 📈 Dashboards Grafana recommandés

Une fois connecté à Grafana, importe ces dashboards :

1. **Node Exporter Full** : ID `1860`
2. **Kubernetes Cluster Monitoring** : ID `7249`
3. **Loki Dashboard** : ID `13639`
4. **Prometheus Stats** : ID `2`

Import via : Dashboards → Import → Load ID

## 🐛 Dépannage

### Prometheus ne démarre pas
```bash
# Vérifier la config
ansible monitoring -m shell -a "/usr/local/bin/promtool check config /etc/prometheus/prometheus.yml"

# Vérifier les permissions
ansible monitoring -m shell -a "ls -la /var/lib/prometheus"
```

### Loki ne reçoit pas de logs
```bash
# Vérifier que Loki écoute
ansible monitoring -m shell -a "curl http://localhost:3100/ready"

# Vérifier les logs d'erreur
ansible monitoring -m shell -a "journalctl -u loki -n 100 --no-pager | grep -i error"
```

### Grafana ne se connecte pas aux datasources
```bash
# Vérifier que les services sont up
ansible monitoring -m shell -a "systemctl status prometheus loki | grep Active"

# Test depuis Grafana
curl http://localhost:9090/-/healthy
curl http://localhost:3100/ready
```

## 📚 Ressources

- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Loki](https://grafana.com/docs/loki/latest/)
- [Documentation Grafana](https://grafana.com/docs/grafana/latest/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

## 🎯 Prochaines étapes

1. ✅ Stack de monitoring installé
2. ⏭️ Installer Promtail + exporters dans Kubernetes
3. ⏭️ Configurer les alertes
4. ⏭️ Créer des dashboards personnalisés
5. ⏭️ Backup automatique des configurations

---

**Questions ?** N'hésite pas ! 🚀

# Makefile
.PHONY: dev preprod

MINIKUBE_CONFIG := ~/.kube/config
K3S_CONFIG := ~/Documents/Projets/Good\ Food/Infra/remote-k3S-config-for-local/config

dev:
	KUBECONFIG=$(MINIKUBE_CONFIG) k9s

preprod: 
	KUBECONFIG=$(K3S_CONFIG) k9s
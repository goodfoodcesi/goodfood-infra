# Makefile
.PHONY: dev preprod apply_dev delete_dev apply_preprod delete_preprod apply_argocd

MINIKUBE_CONFIG := ~/.kube/config
K3S_CONFIG := ~/Documents/Projets/Good\ Food/Infra/remote-k3S-config-for-local/config

dev:
	KUBECONFIG=$(MINIKUBE_CONFIG) k9s

preprod: 
	KUBECONFIG=$(K3S_CONFIG) k9s

apply_dev:
	kubectl apply -f ./dev

delete_dev:
	kubectl delete -f ./dev

apply_preprod:
	kubectl apply -f ./preprod

delete_preprod:
	kubectl delete -f ./preprod

apply_argocd:
	kubectl apply -k ./argocd/install/
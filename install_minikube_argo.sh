#!/bin/bash

# Codes de couleur
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Installation de k3s
echo -e "${GREEN}Installation de k3s...${NC}"
curl -sfL https://get.k3s.io | sh -
echo -e "${GREEN}k3s installé.${NC}"

# Attente que k3s démarre
sleep 10
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
# Vérification de l'installation de k3s
echo -e "${GREEN}Vérification de l'installation de k3s...${NC}"
kubectl get nodes

# Activation de l'addon ingress
#echo -e "${GREEN}Activation de l'addon ingress...${NC}"
#kubectl apply -f https://raw.githubusercontent.com/k3s-io/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Création du namespace Argo CD et installation
echo -e "${GREEN}Création du namespace Argo CD...${NC}"
kubectl create namespace argocd
echo -e "${GREEN}Installation d'Argo CD...${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attente de la fin de l'installation
echo -e "${GREEN}Attente de la fin de l'installation des pods Argo CD...${NC}"
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
echo -e "${GREEN}Argo CD installé.${NC}"

# Affichage des pods dans le namespace argocd
echo -e "${GREEN}Affichage des pods dans le namespace argocd...${NC}"
kubectl get pods -n argocd

# Récupération du mot de passe initial d'Argo CD
echo -e "${GREEN}Récupération du mot de passe initial d'Argo CD...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
echo -e "${GREEN}Le mot de passe initial d'Argo CD est : ${RED}$ARGOCD_PASSWORD${NC}"

# Remplacement des tokens par le contenu de ~/.token
CR_TOKEN=$(cat ~/.token)

# Création des namespaces back et front
kubectl create namespace back
kubectl create namespace front

# Création du secret docker-registry pour l'application back
echo -e "${GREEN}Création du secret docker-registry pour l'application back...${NC}"
kubectl create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=$CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n back
echo -e "${GREEN}Secret docker-registry pour l'application back créé.${NC}"

# Création du secret docker-registry pour l'application front
echo -e "${GREEN}Création du secret docker-registry pour l'application front...${NC}"
kubectl create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=$CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n front
echo -e "${GREEN}Secret docker-registry pour l'application front créé.${NC}"

## Installation de Helm et du plugin helm-secrets
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo -e "${GREEN}Installation de Helm et du plugin helm-secrets...${NC}"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install my-release sealed-secrets/sealed-secrets
#kubectl apply -f master.yaml
# kubectl delete pod my-release-sealed-secrets-5ffdbfc774-7qw7v
echo -e "${GREEN}Helm et le plugin helm installés.${NC}"

# Apply the application manifests
echo -e "${GREEN}Application des manifests des applications...${NC}"
#kubectl apply -n argocd -f https://github.com/quent36987/cook-we-config/blob/main/argocd-applications.yaml

# Fin du script
echo -e "${GREEN}Script terminé.${NC}"

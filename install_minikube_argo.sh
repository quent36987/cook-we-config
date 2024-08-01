#!/bin/bash

# Codes de couleur
BLUE='\033[1;34m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

# Téléchargement et installation de Minikube
echo -e "${GREEN}Téléchargement de Minikube...${NC}"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
echo -e "${GREEN}Installation de Minikube...${NC}"
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo -e "${GREEN}Minikube installé.${NC}"

# Démarrage de Minikube
echo -e "${GREEN}Démarrage de Minikube...${NC}"
minikube start --driver=docker
echo -e "${GREEN}Minikube démarré.${NC}"

# Activation de l'addon ingress
echo -e "${GREEN}Activation de l'addon ingress...${NC}"
minikube addons enable ingress -p minikube
echo -e "${GREEN}Addon ingress activé.${NC}"

# Alias kubectl pour utiliser celui de Minikube
echo -e "${GREEN}Configuration de l'alias kubectl...${NC}"
echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc
source ~/.bashrc

# Création du namespace Argo CD et installation
echo -e "${GREEN}Création du namespace Argo CD...${NC}"
minikube kubectl -- create namespace argocd
echo -e "${GREEN}Installation d'Argo CD...${NC}"
minikube kubectl -- apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attente de la fin de l'installation
echo -e "${GREEN}Attente de la fin de l'installation des pods Argo CD...${NC}"
minikube kubectl -- wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
echo -e "${GREEN}Argo CD installé.${NC}"

# Affichage des pods dans le namespace argocd
echo -e "${GREEN}Affichage des pods dans le namespace argocd...${NC}"
minikube kubectl -- get pods -n argocd

# Récupération du mot de passe initial d'Argo CD
echo -e "${GREEN}Récupération du mot de passe initial d'Argo CD...${NC}"
ARGOCD_PASSWORD=$(minikube kubectl -- -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
echo -e "${GREEN}Le mot de passe initial d'Argo CD est : $ARGOCD_PASSWORD${NC}"

# Remplacement des tokens par le contenu de ~/.token
CR_TOKEN=$(cat ~/.token)

minikube kubectl -- create namespace back
minikube kubectl -- create namespace front

# Création du secret docker-registry pour l'application back
echo -e "${GREEN}Création du secret docker-registry pour l'application back...${NC}"
minikube kubectl -- create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=$CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n back
echo -e "${GREEN}Secret docker-registry pour l'application back créé.${NC}"

# Création du secret docker-registry pour l'application front
echo -e "${GREEN}Création du secret docker-registry pour l'application front...${NC}"
minikube kubectl -- create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=$CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n front
echo -e "${GREEN}Secret docker-registry pour l'application front créé.${NC}"

# Configuration du port forwarding pour Argo CD
echo -e "${GREEN}Configuration du port forwarding pour Argo CD...${NC}"
minikube kubectl -- port-forward svc/argocd-server -n argocd --address 0.0.0.0 8080:443 &
echo -e "${GREEN}Port forwarding configuré. Vous pouvez accéder à Argo CD à l'adresse https://localhost:8080${NC}"

# Fin du script
echo -e "${GREEN}Script terminé.${NC}"

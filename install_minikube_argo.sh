#!/bin/bash

# Téléchargement et installation de Minikube
echo "Téléchargement de Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
echo "Installation de Minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
echo "Minikube installé."

# Démarrage de Minikube
echo "Démarrage de Minikube..."
minikube start
echo "Minikube démarré."

# Activation de l'addon ingress
echo "Activation de l'addon ingress..."
minikube addons enable ingress -p minikube
echo "Addon ingress activé."

# Alias kubectl pour utiliser celui de Minikube
echo "Configuration de l'alias kubectl..."
alias kubectl="minikube kubectl --"

# Création du namespace Argo CD et installation
echo "Création du namespace Argo CD..."
kubectl create namespace argocd
echo "Installation d'Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attente de la fin de l'installation
echo "Attente de la fin de l'installation des pods Argo CD..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
echo "Argo CD installé."

# Affichage des pods dans le namespace argocd
echo "Affichage des pods dans le namespace argocd..."
kubectl get pods -n argocd

# Récupération du mot de passe initial d'Argo CD
echo "Récupération du mot de passe initial d'Argo CD..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode)
echo "Le mot de passe initial d'Argo CD est : $ARGOCD_PASSWORD"

# Remplacement des tokens par le contenu de ~/.token
CR_TOKEN=$(cat ~/.token)

# Création du secret docker-registry pour l'application back
echo "Création du secret docker-registry pour l'application back..."
kubectl create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n back
echo "Secret docker-registry pour l'application back créé."

# Création du secret docker-registry pour l'application front
echo "Création du secret docker-registry pour l'application front..."
kubectl create secret docker-registry ghcr-secret \
--docker-server=ghcr.io \
--docker-username=quent36987 \
--docker-password=CR_TOKEN \
--docker-email=quentin.goujon@epita.fr \
-n front
echo "Secret docker-registry pour l'application front créé."

# Configuration du port forwarding pour Argo CD
echo "Configuration du port forwarding pour Argo CD..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
echo "Port forwarding configuré. Vous pouvez accéder à Argo CD à l'adresse https://localhost:8080"

# Fin du script
echo "Script terminé."

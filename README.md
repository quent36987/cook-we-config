# Config for Cook We !

The goal of the repo is to easy install the back, front, bdd on a cluster with argoCD.

back repo :  https://github.com/quent36987/cook-we

front repo : https://github.com/quent36987/cook-we-app

## Install k3s and argoCD

```bash
echo 'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' > .token

wget https://github.com/quent36987/cook-we-config/raw/main/install_minikube_argo.sh

chmod +x install_minikube_argo.sh

./install_minikube_argo.sh
```


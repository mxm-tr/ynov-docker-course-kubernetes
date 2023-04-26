
## 1. Install the NGINX Ingress Controller

```
helm upgrade --install ingress-nginx ./0-ingress-nginx --namespace ingress-nginx --create-namespace
```

More information: https://kubernetes.github.io/ingress-nginx/deploy/#quick-start


## 2. Install Cert-manager

```
helm install cert-manager ./1-cert-manager --namespace cert-manager --create-namespace
```

More information: https://cert-manager.io/docs/installation/helm/#4-install-cert-manager


# Admin guide

## 0. Recommended: Install the git hooks

This should prevent you from pushing private keys in cleartext:

```
ln -s ../../.githooks/pre-commit ./.git/hooks/pre-commit
```

Secrets are being encrypted using Ansible Vault

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

## 3. Install Capsule

Edit the tenant list in `2-capsule/values.yaml`, and install the helm chart:

```
helm upgrade --install capsule ./2-capsule --namespace capsule-system --create-namespace
```

More information: https://github.com/clastix/capsule/blob/master/charts/capsule/README.md#cert-manager-integration

## 4. Generate user accounts

Generate the kubeconfigs for your user using the `./2-capsule/hack/create-all-users.sh` script.

For example, to generate the kubeconfigs for all csrs in the default namespace, under the `kubeconfigs` directory:

```
./2-capsule/hack/create-all-users.sh kubeconfigs
```

## 5. Encrypt the files

Before distributing the files, make sure you encrypt them:

```bash
ansible-vault encrypt kubeconfigs/*
```

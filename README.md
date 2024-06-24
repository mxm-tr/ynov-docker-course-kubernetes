# User guide

This guide helps you interact with a multi-tenant kubernetes cluster configured using the [Admin Guide](ADMIN.md).

## Prerequisites

Make sure that you have:

* The required `kubectl`, `helm` clients installed,
* A kubeconfig file to communicate with an existing kubernetes cluster.
* `ansible-vault` installed if you need to decrypt the kubeconfig files.

### 1. Decrypt your credentials

```bash
ansible-vault decrypt kubeconfigs/teachers-test*
```

### 2. Log into the kubernetes cluster

```bash
export KUBECONFIG=kubeconfigs/teachers-test.kubeconfig
```

### 3. Create the namespace for your team

```bash
kubectl create ns test
```

If everything is setup properly, you should get:

```bash
kubectl get pods -n test
No resources found in test namespace
```

Hooray 🎉

### 4. Get the public ingress ip of your cluster

Get the public IP address of the ingress controller:

```
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### 5. Configure a DNS entry for your app

Edit the `ingress.hosts` and `ingress.tls` entries in your app's [values.yaml](./4-sample-app/values.yaml).

### 6. Deploy the sample app

```bash
helm -n test upgrade --install my-sample-app ./4-sample-app
```

### 7. Edit the sample app with your own code

Edit the helm chart to use your own app, and upgrade your release:

```bash
helm -n test upgrade --install my-sample-app ./4-sample-app
```

### 8. Get a trusted cert from let's encrypt

Is your app reachable? Now just get a trusted certificate to make it official! Change `letsencrypt-dev` to `letsencrypt-prod` and redeploy your app to make the magic happen! 🎊🤩🍾

### Note about private registries

You may want to use a pull secret to download images from private registries

```bash
docker login
...

kubectl -n test create secret generic dockerhub  --from-file=.dockerconfigjson=/home/mxmtr/.docker/config.json    --type=kubernetes.io/dockerconfigjson
```

```yaml
imagePullSecrets:
  - name: dockerhub
```

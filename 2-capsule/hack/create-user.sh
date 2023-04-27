#!/usr/bin/env bash
# Initial source from https://github.com/clastix/capsule/blob/master/hack/create-user.sh

# This script uses Kubernetes CertificateSigningRequest (CSR) to generate a
# certificate signed by the Kubernetes CA itself.
# It requires cluster admin permission.
#
# e.g.: ./create-user.sh alice oil
#       where `oil` is the Tenant and `alice` the owner

# Exit immediately if a command exits with a non-zero status.
set -e

function check_command() {
    local command=$1

    if ! command -v $command &> /dev/null; then
        echo "Error: ${command} not found"
        exit 1
    fi
}

function show_usage() {
    echo "Usage:"
    echo -e "\t $0 USER TENANT OUTPUT_DIR GROUP(Optional)"
}


check_command openssl
check_command kubectl
check_command jq

USER=$1
TENANT=$2
OUTPUT_DIR=$3
GROUP=$4

if [[ -z ${USER} ]]; then
    echo "User has not been specified!"
    exit 1
fi

if [[ -z ${TENANT} ]]; then
    echo "Tenant has not been specified!"
    exit 1
fi

if [[ -z ${GROUP} ]]; then
    GROUP=capsule.clastix.io
fi

if [[ -z ${OUTPUT_DIR} ]]; then
    echo "Specify the output directory"
    exit 1
fi

OUTPUT_DIR=$(realpath "$OUTPUT_DIR")
if [[ ! -d ${OUTPUT_DIR} ]]; then
    echo "The output directory $OUTPUT_DIR does not exist"
    exit 1
fi

cd "$OUTPUT_DIR"

TMPDIR=$(mktemp -d)
echo "creating certs in TMPDIR ${TMPDIR} "

MERGED_GROUPS=$(echo "/O=$GROUP" | sed "s/,/\/O=/g")
echo "merging groups ${MERGED_GROUPS}"

openssl genrsa -out ${USER}-${TENANT}.key 2048
openssl req -new -key ${USER}-${TENANT}.key -subj "/CN=${USER}${MERGED_GROUPS}" -out ${TMPDIR}/${USER}-${TENANT}.csr

# Clean any previously created CSR for the same user.
#kubectl delete csr ${USER}-${TENANT} 2>/dev/null || true

# Return an error if the CSR already exists
kubectl get csr ${USER}-${TENANT} &>/dev/null && echo "Tokens have already been generated for ${USER} in tenant ${TENANT}. Delete it manually with kubectl delete csr ${USER}-${TENANT} to proceed." && exit 0

#
# Create a new CSR file.
#
if [ $(kubectl version -o json | jq -r .serverVersion.minor) -gt 19 ]; then
cat <<EOF > ${TMPDIR}/${USER}-${TENANT}-csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${USER}-${TENANT}
spec:
  signerName: kubernetes.io/kube-apiserver-client
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/${USER}-${TENANT}.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
else
cat <<EOF > ${TMPDIR}/${USER}-${TENANT}-csr.yaml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${USER}-${TENANT}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/${USER}-${TENANT}.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - client auth
EOF
fi

# Create the CSR
kubectl apply -f ${TMPDIR}/${USER}-${TENANT}-csr.yaml

# Approve and fetch the signed certificate
kubectl certificate approve ${USER}-${TENANT}
kubectl get csr ${USER}-${TENANT} -o jsonpath='{.status.certificate}' | base64 --decode > ${USER}-${TENANT}.crt

# Create the kubeconfig file
CONTEXT=$(kubectl config current-context)
CLUSTER=$(kubectl config view -o jsonpath="{.contexts[?(@.name == \"$CONTEXT\"})].context.cluster}")
SERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${CLUSTER}\"})].cluster.server}")
CA=$(kubectl config view --flatten -o jsonpath="{.clusters[?(@.name == \"${CLUSTER}\"})].cluster.certificate-authority-data}")

cat > ${USER}-${TENANT}.kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $CA
    server: ${SERVER}
  name: ${CLUSTER}
contexts:
- context:
    cluster: ${CLUSTER}
    user: ${USER}
  name: ${USER}-${TENANT}
current-context: ${USER}-${TENANT}
kind: Config
preferences: {}
users:
- name: ${USER}
  user:
    client-certificate: ${USER}-${TENANT}.crt
    client-key: ${USER}-${TENANT}.key
EOF

echo "kubeconfig file is:" ${USER}-${TENANT}.kubeconfig
echo "to use it as" ${USER} "export KUBECONFIG="${USER}-${TENANT}.kubeconfig

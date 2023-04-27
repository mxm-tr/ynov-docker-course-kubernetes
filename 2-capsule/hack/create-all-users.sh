#!/bin/bash

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
    echo -e "\t $0 NAMESPACE OUTPUT_DIR"
}

check_command openssl
check_command kubectl
check_command jq

NAMESPACE=$1
OUTPUT_DIR=$2

if [[ -z ${NAMESPACE} ]]; then
    echo "Namespace has not been specified!"
    show_usage
    exit 1
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

cd "$(dirname "$0")"
for tenant_name in $(kubectl get tenants -o name -n "$NAMESPACE"); do
    tenant_name=$(echo "$tenant_name" | cut -d "/" -f2-)
    kubectl -n "$NAMESPACE" get -ojsonpath="{.spec.owners[].name }" tenant "$tenant_name" | xargs -I USER ./create-user.sh USER "$tenant_name" "$OUTPUT_DIR"
    
done

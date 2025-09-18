#!/bin/bash

set -e

RELEASE_NAME=${1:-my-democrm}
NAMESPACE=${2:-default}
MONGODB_URI="mongodb://admin:password123@mongodb-0.mongodb-headless.default.svc.cluster.local:27017,mongodb-1.mongodb-headless.default.svc.cluster.local:27017/?replicaSet=rs0&authSource=admin"

echo "Generating sealed secret for MongoDB connection..."
echo "Release: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"

if ! command -v kubeseal &> /dev/null; then
    echo "Error: kubeseal is not installed. Please install it first:"
    echo "https://github.com/bitnami-labs/sealed-secrets/releases"
    exit 1
fi

SEALED_DATA=$(echo -n "$MONGODB_URI" | kubeseal --raw --from-file=/dev/stdin --name="$RELEASE_NAME-mongodb-secret" --namespace="$NAMESPACE")

echo ""
echo "Generated sealed secret data:"
echo "mongodb-uri: $SEALED_DATA"
echo ""
echo "Update your templates/sealed-secret.yaml with this value"
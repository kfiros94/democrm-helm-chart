#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CHART_DIR="."
RELEASE_NAME="my-democrm"
NAMESPACE="democrm-test"
VALUES_FILE="values.yaml"

echo -e "${YELLOW}=== DemoCRM Helm Chart Testing Script ===${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Step 1: Validate chart structure
print_status "Step 1: Validating chart structure..."
if helm lint $CHART_DIR; then
    print_status "✓ Chart passes helm lint validation"
else
    print_error "✗ Chart failed helm lint validation"
    exit 1
fi

# Step 2: Update dependencies
print_status "Step 2: Updating dependencies..."
helm dependency update $CHART_DIR

# Step 3: Test template rendering
print_status "Step 3: Testing template rendering..."
if helm template $RELEASE_NAME $CHART_DIR --values $VALUES_FILE --dry-run > /tmp/democrm-templates.yaml; then
    print_status "✓ Templates render successfully"
    echo "  - Templates saved to /tmp/democrm-templates.yaml for review"
else
    print_error "✗ Template rendering failed"
    exit 1
fi

# Step 4: Check if namespace exists
print_status "Step 4: Checking namespace..."
if kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    print_warning "Namespace $NAMESPACE already exists"
else
    print_status "Creating namespace $NAMESPACE"
    kubectl create namespace $NAMESPACE
fi

# Step 5: Dry run installation
print_status "Step 5: Testing installation (dry-run)..."
if helm install $RELEASE_NAME $CHART_DIR --namespace $NAMESPACE --values $VALUES_FILE --dry-run; then
    print_status "✓ Dry-run installation successful"
else
    print_error "✗ Dry-run installation failed"
    exit 1
fi

# Step 6: Ask for actual installation
echo
read -p "Do you want to proceed with actual installation? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Step 6: Installing chart..."
    helm install $RELEASE_NAME $CHART_DIR --namespace $NAMESPACE --values $VALUES_FILE
    
    # Wait for deployment
    print_status "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$RELEASE_NAME -n $NAMESPACE
    
    # Show status
    print_status "Installation completed! Checking status..."
    helm status $RELEASE_NAME -n $NAMESPACE
    
    echo
    print_status "Pods status:"
    kubectl get pods -n $NAMESPACE
    
    echo
    print_status "Services:"
    kubectl get svc -n $NAMESPACE
    
    echo
    print_status "Ingress:"
    kubectl get ingress -n $NAMESPACE
    
    echo
    print_status "To test the application locally, run:"
    echo "  kubectl port-forward svc/$RELEASE_NAME 8080:80 -n $NAMESPACE"
    
    echo
    print_status "To view logs:"
    echo "  kubectl logs -l app.kubernetes.io/name=democrm -n $NAMESPACE"
    
    echo
    print_status "To uninstall:"
    echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
    echo "  kubectl delete namespace $NAMESPACE"
    
else
    print_status "Installation skipped"
fi

print_status "Testing completed!"
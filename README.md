# Demo CRM Helm Chart

[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.19+-blue.svg)](https://kubernetes.io/)
[![Helm](https://img.shields.io/badge/Helm-3.0+-blue.svg)](https://helm.sh/)
[![MongoDB](https://img.shields.io/badge/MongoDB-Community-green.svg)](https://www.mongodb.com/)

A production-ready Helm chart for deploying Demo CRM application with MongoDB replica set and automated SSL certificate management.

## Overview

This Helm chart deploys a complete CRM application stack including:
- Next.js-based Demo CRM application with high availability (2 replicas)
- MongoDB replica set for data persistence and fault tolerance
- Automated SSL certificate management via cert-manager and Let's Encrypt
- Nginx Ingress Controller for HTTP/HTTPS traffic routing
- Optional Sealed Secrets for enhanced security

## Architecture

The chart creates a modern, production-ready Kubernetes deployment:

```
Internet → DNS → Ingress Controller → Ingress → Service → Demo CRM Pods → MongoDB Replica Set
              ↘                                                            ↗
               cert-manager (Automated SSL certificates)
```

### Key Features

- **High Availability**: 2 application replicas with health checks
- **Database Reliability**: MongoDB 3-node replica set (2 data + 1 arbiter)
- **Security**: Automated SSL certificates, security contexts, RBAC
- **Scalability**: Resource management with requests and limits
- **Production Ready**: Proper labeling, monitoring hooks, and testing

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure
- DNS domain for SSL certificates (if enabling HTTPS)

## Quick Start

```bash
# Add required Helm repositories
helm repo add mongodb https://mongodb.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Clone this repository
git clone https://github.com/kfiros94/democrm-helm-chart.git
cd democrm-helm-chart

# Install with default values
helm install my-democrm .
```

## Configuration

### Core Application Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `democrm.replicaCount` | Number of Demo CRM replicas | `2` |
| `democrm.image.repository` | Demo CRM image repository | `pwstaging/demo-crm` |
| `democrm.image.tag` | Demo CRM image tag | `latest` |
| `democrm.resources.limits.cpu` | CPU resource limits | `1000m` |
| `democrm.resources.limits.memory` | Memory resource limits | `1Gi` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts[0].host` | Hostname for the ingress | `kfir-cowsay.ddns.net` |
| `ingress.tls[0].secretName` | TLS secret name | `democrm-tls` |

### Dependencies

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Enable MongoDB subchart | `false` |
| `certManager.enabled` | Enable cert-manager subchart | `false` |
| `ingressNginx.enabled` | Enable ingress-nginx subchart | `false` |
| `sealedSecrets.enabled` | Enable sealed-secrets subchart | `false` |

## Installation Scenarios

### Scenario 1: Fresh Installation (All Dependencies)

For a completely new cluster:

```bash
# Enable all dependencies
helm install my-democrm . \
  --set mongodb.enabled=true \
  --set certManager.enabled=true \
  --set ingressNginx.enabled=true
```

### Scenario 2: Existing Infrastructure

When you already have MongoDB, cert-manager, and ingress-nginx installed:

```bash
# Use existing infrastructure
helm install my-democrm . \
  --set mongodb.enabled=false \
  --set certManager.enabled=false \
  --set ingressNginx.enabled=false
```

### Scenario 3: Custom Values

```bash
# Create custom values file
cat > my-values.yaml << EOF
democrm:
  replicaCount: 3
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
      
ingress:
  hosts:
    - host: my-crm.example.com
      paths:
        - path: /
          pathType: Prefix

mongodb:
  enabled: true
EOF

# Install with custom values
helm install my-democrm . -f my-values.yaml
```

## Bonus Features

### Helm Hooks for CRD Management

The chart includes pre-install hooks for managing cert-manager CRDs:

- Automatic CRD installation before cert-manager deployment
- Proper resource ordering with hook weights
- Idempotent installation (won't reinstall existing CRDs)

```bash
# Enable CRD management hooks
helm install my-democrm . --set certManager.enabled=true
```

### Sealed Secrets Integration

For enhanced security, the chart supports Sealed Secrets:

```bash
# Install kubeseal CLI
brew install kubeseal

# Generate sealed secret
./scripts/generate-sealed-secret.sh my-democrm default

# Enable sealed secrets
helm install my-democrm . \
  --set sealedSecrets.enabled=true \
  --set security.mongodbSecret.useSealed=true
```

## Testing

### Helm Tests

```bash
# Run connectivity tests
helm test my-democrm
```

### Manual Testing

```bash
# Check deployment status
kubectl get pods -l app.kubernetes.io/instance=my-democrm

# Test application
kubectl port-forward svc/my-democrm 8080:80
curl http://localhost:8080

# Check MongoDB connection
kubectl exec -it deployment/my-democrm -- /bin/sh
# Inside pod: test MongoDB connection
```

## Monitoring and Observability

The chart includes proper labeling for monitoring tools:

```bash
# View all resources
kubectl get all -l app.kubernetes.io/instance=my-democrm

# Check logs
kubectl logs -l app.kubernetes.io/name=democrm --tail=100
```

## Upgrading

```bash
# Update dependencies
helm dependency update

# Upgrade release
helm upgrade my-democrm . -f my-values.yaml

# Rollback if needed
helm rollback my-democrm 1
```

## Uninstalling

```bash
# Remove the release
helm uninstall my-democrm

# Clean up PVCs (if using MongoDB)
kubectl delete pvc -l app.kubernetes.io/instance=my-democrm
```

## Development

### Linting and Validation

```bash
# Lint the chart
helm lint .

# Validate templates
helm template my-democrm . --debug

# Package the chart
helm package .
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly (`helm lint .` and `helm template .`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Troubleshooting

### Common Issues

**Pods stuck in Pending:**
```bash
kubectl describe pod <pod-name>
# Check for resource constraints or PVC issues
```

**SSL Certificate not working:**
```bash
kubectl get certificate
kubectl describe certificate democrm-tls
kubectl get challenges
```

**MongoDB connection failed:**
```bash
kubectl logs -l app.kubernetes.io/name=democrm
kubectl get pods -l app.kubernetes.io/name=mongodb
```

### Debug Commands

```bash
# View Helm release info
helm status my-democrm
helm get values my-democrm

# Check all resources
kubectl get all -l app.kubernetes.io/instance=my-democrm

# View events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📫 Email: kfiramoyal@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/kfiros94/democrm-helm-chart/issues)
- 📖 Documentation: This README and inline comments

## Acknowledgments

- [MongoDB Community Helm Charts](https://github.com/mongodb/helm-charts)
- [cert-manager](https://cert-manager.io/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Sealed Secrets](https://sealed-secrets.netlify.app/)
# Demo CRM Helm Chart

A production-ready Helm chart for deploying Demo CRM application with MongoDB replica set and automated SSL certificate management.

## Description

This Helm chart deploys a complete CRM application stack including:
- Next.js-based Demo CRM application
- MongoDB replica set for high availability
- Automated SSL certificate management via cert-manager
- Nginx Ingress Controller for traffic routing

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure

## Architecture Overview

```
Internet → DNS → LoadBalancer → Ingress Controller → Ingress → Service → Deployment → Pods
                                      ↓
                              cert-manager (SSL Certs)
                                      ↓
                              MongoDB Replica Set (rs0)
```

### Components

- **Demo CRM Application**: Next.js frontend with 2 replicas for HA
- **MongoDB**: 3-node replica set (2 data + 1 arbiter) for data persistence
- **Nginx Ingress Controller**: HTTP/HTTPS traffic routing and load balancing
- **cert-manager**: Automated SSL certificate management via Let's Encrypt
- **Persistent Storage**: 5Gi storage per MongoDB data node

## Installation

### Quick Start

```bash
# Add required Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install the chart
helm install my-democrm ./democrm-chart
```

### Custom Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd democrm-chart
   ```

2. Customize values (copy and edit):
   ```bash
   cp values.yaml my-values.yaml
   # Edit my-values.yaml with your specific configuration
   ```

3. Install with custom values:
   ```bash
   helm install my-democrm . -f my-values.yaml
   ```

4. Update dependencies:
   ```bash
   helm dependency update
   ```

## Configuration

The following table lists the configurable parameters and their default values.

### Demo CRM Application Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `democrm.replicaCount` | Number of Demo CRM replicas | `2` |
| `democrm.image.repository` | Demo CRM image repository | `pwstaging/demo-crm` |
| `democrm.image.tag` | Demo CRM image tag | `latest` |
| `democrm.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `democrm.config.logLevel` | Application log level | `info` |
| `democrm.config.persistence` | Enable persistence features | `true` |
| `democrm.resources.limits.cpu` | CPU resource limits | `1000m` |
| `democrm.resources.limits.memory` | Memory resource limits | `1Gi` |
| `democrm.resources.requests.cpu` | CPU resource requests | `500m` |
| `democrm.resources.requests.memory` | Memory resource requests | `256Mi` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts[0].host` | Hostname for the ingress | `kfir-cowsay.ddns.net` |
| `ingress.tls[0].secretName` | TLS secret name | `democrm-tls` |

### MongoDB Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mongodb.enabled` | Enable MongoDB subchart | `true` |
| `mongodb.auth.enabled` | Enable MongoDB authentication | `true` |
| `mongodb.auth.rootUser` | MongoDB root username | `admin` |
| `mongodb.auth.rootPassword` | MongoDB root password | `password123` |
| `mongodb.architecture` | MongoDB architecture | `replicaset` |
| `mongodb.replicaCount` | Number of MongoDB replicas | `2` |
| `mongodb.persistence.enabled` | Enable MongoDB persistence | `true` |
| `mongodb.persistence.size` | MongoDB PVC size | `5Gi` |

### Certificate Manager Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `certManager.enabled` | Enable cert-manager subchart | `true` |
| `certManager.clusterIssuer.name` | ClusterIssuer name | `letsencrypt-prod` |
| `certManager.clusterIssuer.email` | Email for Let's Encrypt | `kfiramoyal@gmail.com` |

## Testing

### Run Helm Tests

```bash
# Run the built-in connectivity test
helm test my-democrm
```

### Manual Testing

1. Check deployment status:
   ```bash
   kubectl get pods -l app.kubernetes.io/instance=my-democrm
   ```

2. Test application connectivity:
   ```bash
   kubectl port-forward svc/my-democrm 8080:80
   curl http://localhost:8080
   ```

3. Test MongoDB connection:
   ```bash
   export MONGODB_ROOT_PASSWORD=$(kubectl get secret my-democrm-mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
   kubectl run mongodb-client --rm -i --tty --restart='Never' \
     --image docker.io/bitnami/mongodb:8.0.13-debian-12-r0 \
     --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" \
     --command -- mongosh admin --host "my-democrm-mongodb-0.my-democrm-mongodb-headless:27017" \
     --authenticationDatabase admin -u admin -p $MONGODB_ROOT_PASSWORD
   ```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**
   ```bash
   kubectl describe pod <pod-name>
   # Check for resource constraints or PVC issues
   ```

2. **SSL Certificate not issuing**
   ```bash
   kubectl get certificate
   kubectl describe certificate democrm-tls
   kubectl get challenges
   ```

3. **MongoDB connection issues**
   ```bash
   kubectl logs -l app.kubernetes.io/name=mongodb
   kubectl get pods -l app.kubernetes.io/name=mongodb
   ```

4. **Ingress not working**
   ```bash
   kubectl get ingress
   kubectl describe ingress my-democrm
   kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
   ```

### Debug Commands

```bash
# Check all resources created by the chart
kubectl get all -l app.kubernetes.io/instance=my-democrm

# View application logs
kubectl logs -l app.kubernetes.io/name=democrm --tail=100

# Check Helm release status
helm status my-democrm

# View Helm release values
helm get values my-democrm
```

## Upgrading

```bash
# Update dependencies
helm dependency update

# Upgrade the release
helm upgrade my-democrm . -f my-values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall my-democrm

# Clean up PVCs (if needed)
kubectl delete pvc -l app.kubernetes.io/instance=my-democrm
```

## Development

### Linting

```bash
helm lint .
```

### Template Rendering

```bash
helm template my-democrm . --debug
```

### Packaging

```bash
helm package .
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue in the repository or contact the maintainers.
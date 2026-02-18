# Sentinel Split - Quick Reference

## Essential Commands

### Terraform

```bash
# Initialize
cd terraform && terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

### kubectl Configuration

```bash
# Gateway cluster
aws eks update-kubeconfig --name eks-sentinel-v1-gateway --region us-west-2

# Backend cluster
aws eks update-kubeconfig --name eks-sentinel-v1-backend --region us-west-2

# Switch context
kubectl config use-context eks-sentinel-v1-gateway
kubectl config use-context eks-sentinel-v1-backend
```

### Testing

```bash
# Get gateway URL
kubectl --context eks-sentinel-v1-gateway get svc gateway-proxy

# Test end-to-end
GATEWAY_URL=$(kubectl --context eks-sentinel-v1-gateway get svc gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$GATEWAY_URL/

# Expected: {"message": "Hello from backend", ...}
```

## Resource Names

| Resource | Name |
|----------|------|
| **Gateway VPC** | gateway-vpc (10.0.0.0/16) |
| **Backend VPC** | backend-vpc (10.1.0.0/16) |
| **Gateway Cluster** | eks-sentinel-v1-gateway |
| **Backend Cluster** | eks-sentinel-v1-backend |
| **Gateway Service** | gateway-proxy (LoadBalancer) |
| **Backend Service** | backend-service (ClusterIP) |

## IAM Roles

- `eks-sentinel-v1-gateway-cluster-role`
- `eks-sentinel-v1-gateway-node-role`
- `eks-sentinel-v1-backend-cluster-role`
- `eks-sentinel-v1-backend-node-role`

## Helpful Scripts

```bash
# Configure kubectl for both clusters
./scripts/configure-kubectl.sh   # Linux/macOS
.\scripts\configure-kubectl.ps1  # Windows PowerShell

# Get backend service IP
./scripts/get-backend-ip.sh   # Linux/macOS
.\scripts\get-backend-ip.ps1  # Windows PowerShell

# Test connectivity
./scripts/test-connectivity.sh

# Destroy all infrastructure
./scripts/destroy.sh
```

## Key Files

| Path | Purpose |
|------|---------|
| `terraform/` | Infrastructure as Code |
| `apps/backend/` | Backend application (Flask) |
| `apps/gateway/` | Gateway proxy (NGINX) |
| `k8s/backend/` | Backend Kubernetes manifests |
| `k8s/gateway/` | Gateway Kubernetes manifests |
| `.github/workflows/` | CI/CD pipelines |

## Network Architecture

```
Internet → NLB → Gateway Pods (10.0.x.x) → VPC Peering → Backend Pods (10.1.x.x)
              eks-sentinel-v1-gateway                      eks-sentinel-v1-backend
```

## Security

- **Backend access**: Restricted to 10.0.0.0/16 (gateway VPC)
- **NetworkPolicy**: `backend-allow-gateway`
- **Service type**: Backend = ClusterIP (internal only)
- **IAM**: Least privilege, scoped role names

## Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Check AWS credentials: `aws sts get-caller-identity` |
| Can't reach backend | Verify backend IP in ConfigMap |
| LB pending | Check subnet tags and AWS LB controller |
| Terraform fails | Ensure IAM roles follow `eks-*` naming |

## CI/CD

GitHub Actions workflows:
- **Terraform**: `.github/workflows/terraform.yml`
- **Deploy**: `.github/workflows/deploy.yml`
- **Security**: `.github/workflows/security.yml`

Required secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

# Sentinel Split - DevSecOps Challenge

A production-ready dual-VPC, dual-EKS architecture demonstrating secure cross-cluster communication, infrastructure as code, and CI/CD best practices.

## 🏗️ Architecture Overview

This project implements the **Rapyd Sentinel** split architecture:

- **Gateway Layer (Public)**: Internet-facing proxy in `vpc-gateway` with `eks-imtiaz-gateway` cluster
- **Backend Layer (Private)**: Internal services in `vpc-backend` with `eks-imtiaz-backend` cluster  
- **Secure Communication**: VPC peering with security groups and NetworkPolicy enforcement

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS us-west-2                            │
├─────────────────────────────────┬───────────────────────────────┤
│  vpc-gateway (10.0.0.0/16)      │  vpc-backend (10.1.0.0/16)    │
│  ┌───────────────────────────┐  │  ┌───────────────────────────┐│
│  │   eks-gateway cluster     │  │  │   eks-backend cluster     ││
│  │  ┌─────────────────────┐  │  │  │  ┌─────────────────────┐ ││
│  │  │  Gateway Proxy      │──┼──┼──┼─▶│  Backend Service    │ ││
│  │  │  (NGINX)            │  │  │  │  │  (Flask)            │ ││
│  │  │  LoadBalancer (*)   │  │  │  │  │  ClusterIP          │ ││
│  │  └─────────────────────┘  │  │  │  └─────────────────────┘ ││
│  └───────────────────────────┘  │  └───────────────────────────┘│
│     │                            │             ▲                 │
│     │ Internet                   │             │                 │
│     ▼                            │    NetworkPolicy Restriction  │
│  Public Access                   │    (Only allow 10.0.0.0/16)   │
└─────────────────────────────────┴───────────────────────────────┘
          (*) Public LoadBalancer          VPC Peering Connection
```

## 📋 Prerequisites

- **AWS Account** with provided credentials (scoped IAM permissions)
- **Terraform** >= 1.5.0
- **kubectl** >= 1.28
- **AWS CLI** >= 2.0
- **Docker** (for local testing)
- **Git** and **GitHub** account (for CI/CD)

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/sentinel-split.git
cd sentinel-split
```

### 2. Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### 3. Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply (creates VPCs, EKS clusters, peering - takes ~15-20 mins)
terraform apply
```

### 4. Configure kubectl

```bash
# Use the helper script
chmod +x scripts/*.sh
./scripts/configure-kubectl.sh

# Or manually
aws eks update-kubeconfig --name eks-gateway --region us-west-2
aws eks update-kubeconfig --name eks-backend --region us-west-2
```

### 5. Deploy Applications

**Important**: Update image references in manifests first:

```bash
# Replace GITHUB_USERNAME with your GitHub username in:
# - k8s/backend/deployment.yaml
# - k8s/gateway/deployment.yaml
```

Deploy backend:
```bash
kubectl --context eks-backend apply -f k8s/backend/
```

Get backend IP and update gateway config:
```bash
./scripts/get-backend-ip.sh

# Update k8s/gateway/configmap.yaml with the backend IP
kubectl --context eks-gateway apply -f k8s/gateway/
```

### 6. Test Connectivity

```bash
# Get gateway LoadBalancer URL
kubectl --context eks-gateway get svc gateway-proxy

# Test (wait 2-3 mins for LB)
curl http://<GATEWAY-URL>/
# Expected: {"message": "Hello from backend", ...}

# Or use the helper script
./scripts/test-connectivity.sh
```

## 🏗️ Infrastructure Details

### VPC Configuration

| Component | Gateway VPC | Backend VPC |
|-----------|------------|-------------|
| **CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Private Subnets** | 2 (across AZs) | 2 (across AZs) |
| **Public Subnets** | 2 (for NAT GWs) | 2 (for NAT GWs) |
| **NAT Gateways** | 2 (HA) | 2 (HA) |
| **Internet Gateway** | ✓ | ✓ |

### EKS Clusters

| Setting | Value |
|---------|-------|
| **Kubernetes Version** | 1.28 |
| **Node Instance Type** | t3.medium |
| **Desired Capacity** | 2 nodes per cluster |
| **Min/Max Size** | 2-4 nodes |
| **IAM Roles** | `eks-*-cluster-role`, `eks-*-node-role` |

### Networking & Security

**VPC Peering**: Bidirectional routes between gateway and backend VPCs

**Security Groups**:
- **Gateway nodes**: Allow outbound to backend VPC CIDR
- **Backend nodes**: Allow inbound only from gateway VPC CIDR (10.0.0.0/16)

**NetworkPolicy**: Backend pods restricted to accept traffic from 10.0.0.0/16 only

## 🔐 Security Model

### Defense in Depth

1. **Network Isolation**: Separate VPCs for gateway and backend
2. **No Public Backend**: Backend service is ClusterIP only (internal)
3. **Security Groups**: AWS-level firewall restricting backend access
4. **NetworkPolicy**: Kubernetes-level pod network isolation
5. **IAM  Least Privilege**: Roles follow `eks-` and `sentinel-` naming constraints
6. **Private Subnets**: EKS nodes run in private subnets only

### NetworkPolicy Explanation

The [`k8s/backend/networkpolicy.yaml`](k8s/backend/networkpolicy.yaml) restricts ingress to backend pods:

```yaml
ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/16  # Only gateway VPC
    ports:
    - protocol: TCP
      port: 8080
```

**Why it works**: Even though pods are in separate clusters, VPC peering allows IP-level communication. The NetworkPolicy ensures only traffic originating from the gateway VPC CIDR can reach backend pods.

## 🔄 CI/CD Pipeline

Three GitHub Actions workflows automate validation and deployment:

### 1. Terraform Workflow (`.github/workflows/terraform.yml`)

**Triggers**: Push to `main`, PRs affecting `terraform/`

**Jobs**:
- **Validate**: `terraform fmt`, `terraform validate`, `tflint`
- **Plan**: Generate plan on PRs, comment results
- **Apply**: Auto-apply on main branch (production environment gate)

### 2. Deployment Workflow (`.github/workflows/deploy.yml`)

**Triggers**: Push to `main`, PRs affecting `apps/` or `k8s/`

**Jobs**:
- **Validate**: `kubectl apply --dry-run=client`
- **Build**: Build and push images to ghcr.io
- **Deploy Backend**: Deploy to eks-backend
- **Deploy Gateway**: Deploy to eks-gateway  
- **Test**: Verify end-to-end connectivity

### 3. Security Workflow (`.github/workflows/security.yml`)

**Triggers**: Push, PRs, weekly schedule

**Jobs**:
- **Terraform Security**: tfsec, Checkov
- **Container Security**: Trivy vulnerability scanning

### GitHub Secrets Required

Set these in your repository settings:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
GITHUB_TOKEN  # Auto-provided
```

## 💰 Cost Optimization

**Monthly cost estimate** (~$200-250 USD):

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| EKS Clusters | 2 | ~$146 |
| NAT Gateways | 4 | ~$128 |
| Network Load Balancer | 1 | ~$16 |
| EC2 Nodes (t3.medium) | 4 | ~$60 |
| **Total** | | **~$350** |

### Cost Reduction Strategies

**For Development**:
- Reduce to 1 NAT Gateway per VPC (save ~$64/mo)
- Use t3.small instances (save ~$30/mo)
- Single-node clusters during testing (save ~$30/mo)
- Scheduled shutdown (e.g., nights/weekends)

**For Production**:
- Consider Fargate for serverless nodes
- Use Spot instances for non-critical workloads
- Implement auto-scaling with cluster-autoscaler
- VPC endpoints to reduce NAT Gateway data transfer costs

## 🎯 Design Trade-offs

### What Was Simplified (3-Day Constraint)

| Area | Current Approach | Production Alternative |
|------|------------------|----------------------|
| **DNS Resolution** | Manual IP configuration | AWS Cloud Map or internal NLB |
| **TLS** | No TLS | mTLS with cert-manager + Let's Encrypt |
| **Observability** | CloudWatch logs only | Prometheus, Grafana, Jaeger |
| **Secrets** | ConfigMaps | AWS Secrets Manager / Vault |
| **GitOps** | Direct kubectl apply | ArgoCD or Flux |
| **Service Mesh** | None | Istio or Linkerd for advanced traffic management |

### IAM Permission Limitations

**Constraints Encountered**:
- Limited to `eks-*` and `sentinel-*` role naming prefixes
- Cannot create VPC Flow Logs (permission denied) - documented assumption
- Cannot enable all EKS control plane logs (documented workaround)

**Workarounds**:
- Used allowed IAM role naming patterns
- Enabled subset of control plane logs (api, audit, authenticator)
- Documented missing features for production deployment

## 🔮 Next Steps & Production Improvements

### Immediate Priorities

1. **Service Discovery**: Replace manual IP with AWS Cloud Map
2. **TLS/mTLS**: Encrypt traffic between gateway and backend
3. **Monitoring**: Deploy Prometheus/Grafana stack
4. **Secrets Management**: Integrate AWS Secrets Manager or Vault
5. **Auto-scaling**: Configure HPA and Cluster Autoscaler

### Long-term Enhancements

6. **Service Mesh**: Deploy Istio/Linkerd for advanced traffic management
7. **GitOps**: Migrate to ArgoCD for declarative deployments
8. **Multi-environment**: Add dev/staging/prod environments
9. **Advanced Ingress**: AWS ALB Ingress Controller with WAF
10. **Disaster Recovery**: Cross-region replication and backup strategies
11. **Compliance**: Pod Security Standards, OPA/Gatekeeper policies
12. **Logging**: Centralized logging with ELK or CloudWatch Insights
13. **Testing**: Integration tests, chaos engineering (Chaos Mesh)

### Advanced Security

- **IRSA (IAM Roles for Service Accounts)**: Fine-grained pod permissions
- **Pod Security Admission**: Restrict pod capabilities
- **Network egress filtering**: Restrict outbound traffic by domain
- **Image signing**: Cosign for container image verification
- **Vulnerability scanning**: Automated CVE detection in CI/CD

## 📁 Project Structure

```
sentinel-split/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Root orchestration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Infrastructure outputs
│   ├── provider.tf           # AWS provider config
│   ├── backend.tf            # State backend (optional S3)
│   └── modules/
│       ├── vpc/              # Reusable VPC module
│       ├── eks/              # Reusable EKS module
│       └── vpc-peering/      # VPC peering module
├── apps/
│   ├── backend/              # Flask backend application
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── requirements.txt
│   └── gateway/              # NGINX reverse proxy
│       ├── Dockerfile
│       ├── nginx.conf.template
│       └── docker-entrypoint.sh
├── k8s/
│   ├── backend/              # Backend K8s manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── networkpolicy.yaml
│   └── gateway/              # Gateway K8s manifests
│       ├── deployment.yaml
│       ├── service.yaml
│       └── configmap.yaml
├── .github/workflows/        # CI/CD pipelines
│   ├── terraform.yml         # Terraform automation
│   ├── deploy.yml            # App deployment
│   └── security.yml          # Security scanning
├── scripts/                  # Helper utilities
│   ├── configure-kubectl.sh
│   ├── get-backend-ip.sh
│   ├── test-connectivity.sh
│   └── destroy.sh
├── ARCHITECTURE.md           # Detailed architecture docs
└── README.md                 # This file
```

## 🧪 Testing & Validation

### Automated Tests

Run locally before committing:

```bash
# Terraform validation
cd terraform
terraform fmt -check -recursive
terraform validate
tflint --recursive

# Kubernetes manifests
kubectl apply --dry-run=client -f k8s/backend/
kubectl apply --dry-run=client -f k8s/gateway/
```

### Manual Validation Checklist

- [ ] Both VPCs created with correct CIDRs
- [ ] VPC peering connection active
- [ ] Both EKS clusters operational
- [ ] Security groups allow gateway → backend
- [ ] NetworkPolicy enforced on backend
- [ ] Gateway LoadBalancer publicly accessible
- [ ] Backend NOT publicly accessible
- [ ] End-to-end connectivity working (gateway → backend)

## 🔧 Troubleshooting

### Gateway can't reach backend

```bash
# Check backend pod IP
kubectl --context eks-backend get pods -o wide

# Check security groups allow gateway VPC CIDR
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=eks-imtiaz-backend-node-sg"

# Check NetworkPolicy
kubectl --context eks-imtiaz-backend describe networkpolicy backend-allow-gateway

# Test from gateway pod
kubectl --context eks-imtiaz-gateway exec -it deployment/gateway-proxy -- curl <BACKEND_IP>:80
```

### LoadBalancer stuck in pending

```bash
# Check service
kubectl --context eks-imtiaz-gateway describe svc gateway-proxy

# Check AWS Load Balancer Controller logs
kubectl --context eks-imtiaz-gateway logs -n kube-system deployment/aws-load-balancer-controller
```

### Cluster access denied

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Update kubeconfig
aws eks update-kubeconfig --name eks-imtiaz-gateway --region us-west-2
```

## 📚 Additional Resources

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes NetworkPolicy Guide](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 🤝 Contributing

This is a technical challenge project. For improvements, please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

## 📄 License

This project is created for the DevSecOps Technical Challenge.

---

**Project**: Sentinel Split  
**Author**: Imtiaz Waraich
**Challenge**: Rapyd DevSecOps  
**Completion Date**: February 2026

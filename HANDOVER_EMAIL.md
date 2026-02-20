# Sentinel Split — Project Handover Email

---

**To:** [Rapyd DevSecOps Examiner]  
**From:** Imtiaz Waraich  
**Date:** February 19, 2026  
**Subject:** Sentinel Split – DevSecOps Challenge Submission Handover

---

Dear Examiner,

I'm handing over the **Sentinel Split** DevSecOps challenge project for your assessment. Below is everything you need to deploy, evaluate, and test the solution end to end.

---

## 📦 Repository

**GitHub:** https://github.com/imtiazwaraich/sentinel-split  
**Branch:** `main`

---

## 🏗️ What Was Built

A **production-grade dual-VPC, dual-EKS architecture** on AWS (`us-west-2`) demonstrating:

- **Split-cluster security**: Gateway cluster (public) + Backend cluster (private, isolated)
- **VPC Peering** with explicit route tables and bidirectional CIDR rules
- **Network Security**: AWS Security Groups (L3/L4) + Kubernetes NetworkPolicy (L7) — defence in depth
- **Infrastructure as Code**: Full Terraform with reusable VPC, EKS, and VPC-Peering modules
- **CI/CD Pipelines**: Three GitHub Actions workflows (Terraform, Deploy, Security)
- **Container Images**: Flask (Python) backend + NGINX reverse-proxy gateway, published to GitHub Container Registry (GHCR)

---

## ⚙️ How to Evaluate

### Step 1 — Prerequisites

Install on your machine:
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [Terraform >= 1.5.0](https://developer.hashicorp.com/terraform/install)
- [kubectl >= 1.30](https://kubernetes.io/docs/tasks/tools/)
- Docker (optional — for local image builds)

### Step 2 — Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="<provided-key>"
export AWS_SECRET_ACCESS_KEY="<provided-secret>"
export AWS_DEFAULT_REGION="us-west-2"
```

Verify access:
```bash
aws sts get-caller-identity
```

### Step 3 — Deploy Infrastructure (Terraform)

```bash
cd terraform
terraform init
terraform plan          # review the plan (~25 resources)
terraform apply         # takes ~15–20 minutes
```

When complete, note the outputs:
```bash
terraform output        # shows cluster names, configure_kubectl commands
```

### Step 4 — Configure kubectl

```bash
# Linux/macOS
./scripts/configure-kubectl.sh

# Windows PowerShell
.\scripts\configure-kubectl.ps1

# Or manually with the terraform outputs:
aws eks update-kubeconfig --name eks-sentinel-v1-gateway --region us-west-2
aws eks update-kubeconfig --name eks-sentinel-v1-backend --region us-west-2
```

### Step 5 — Deploy Applications

The CI/CD pipeline (GitHub Actions) handles this automatically on push to `main`.  
For a manual deployment:

```bash
# 1. Build and push images (substitute your GHCR credentials)
echo $GITHUB_TOKEN | docker login ghcr.io -u imtiazwaraich --password-stdin

docker build -t ghcr.io/imtiazwaraich/sentinel-split/sentinel-backend:latest ./apps/backend
docker push ghcr.io/imtiazwaraich/sentinel-split/sentinel-backend:latest

docker build -t ghcr.io/imtiazwaraich/sentinel-split/sentinel-gateway:latest ./apps/gateway
docker push ghcr.io/imtiazwaraich/sentinel-split/sentinel-gateway:latest

# 2. Deploy backend
kubectl --context eks-sentinel-v1-backend apply -f k8s/backend/
kubectl --context eks-sentinel-v1-backend rollout status deployment/backend-service

# 3. Get backend pod IP
./scripts/get-backend-ip.sh   # prints the IP

# 4. Update configmap and deploy gateway
# Edit k8s/gateway/configmap.yaml: set BACKEND_SERVICE_HOST to the IP from step 3
# Deploy the configuration template first, then the gateway
kubectl --context eks-sentinel-v1-gateway apply -f k8s/gateway/nginx-template-configmap.yaml
kubectl --context eks-sentinel-v1-gateway apply -f k8s/gateway/
kubectl --context eks-sentinel-v1-gateway rollout status deployment/gateway-proxy
```

### Step 6 — Test End-to-End Connectivity

```bash
# Get the public LoadBalancer URL
kubectl --context eks-sentinel-v1-gateway get svc gateway-proxy

# Wait 2–3 minutes for AWS NLB DNS propagation, then test:
curl http://<GATEWAY-LB-URL>/health
# Expected: Gateway healthy

curl http://<GATEWAY-LB-URL>/
# Expected: {"message": "Hello from backend", "pod": "backend-service-xxxx", "service": "sentinel-backend"}

# Or run the helper script
./scripts/test-connectivity.sh   # Linux/macOS
.\scripts\test-connectivity.ps1  # Windows PowerShell
```

### Step 7 — Verify Security Model

```bash
# Confirm backend has NO public endpoint (ClusterIP only)
kubectl --context eks-sentinel-v1-backend get svc
# Should show: backend-service   ClusterIP   <cluster-ip>   <none>   80/TCP

# Confirm NetworkPolicy is applied
kubectl --context eks-sentinel-v1-backend describe networkpolicy backend-allow-gateway

# Confirm backend is reachable ONLY through gateway
kubectl --context eks-sentinel-v1-gateway exec -it deployment/gateway-proxy -- \
  curl http://<BACKEND_POD_IP>:8080
# Expected: 200 OK {"message": "Hello from backend"}
```

---

## 🔑 GitHub Secrets Required (for CI/CD)

Add the following secrets in **Repository Settings → Secrets → Actions**:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `GITHUB_TOKEN` | Auto-provided by GitHub Actions |

Also configure a **GitHub Environment** named `production` (Settings → Environments) so the deploy and apply jobs require approval before running against production AWS.

---

## 🧪 CI/CD Pipeline — What to Check on GitHub Actions

After pushing to `main`, three workflows trigger:

| Workflow | File | What to Verify |
|----------|------|----------------|
| **Terraform** | `terraform.yml` | `terraform validate` + `tflint` passes; apply runs on push to main |
| **Deploy** | `deploy.yml` | `kubeconform` validation passes (no cluster needed); images build and push to GHCR; both clusters deploy successfully |
| **Security** | `security.yml` | `tfsec`, `Checkov` (soft-fail); Trivy SARIF results uploaded to GitHub Security tab |

---

## 🧹 Teardown (Important — Cost)

Infrastructure costs **~$350/month**. Destroy when evaluation is complete:

```bash
# Linux/macOS
./scripts/destroy.sh

# Or manually
cd terraform
terraform destroy
```

---

## 📄 Documentation References

| Document | Purpose |
|----------|---------|
| [`README.md`](README.md) | Complete setup and deployment guide |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Technical deep-dive: VPCs, EKS, security layers, traffic flow |
| [`PROJECT_SUMMARY.md`](PROJECT_SUMMARY.md) | High-level project summary and design decisions |
| [`QUICKREF.md`](QUICKREF.md) | Quick reference cheat-sheet for common commands |

---

## ⚠️ Known Limitations (by Design — 3-Day Constraint)

| Area | Current | Production Alternative |
|------|---------|----------------------|
| Service Discovery | Manual pod IP in ConfigMap | AWS Cloud Map |
| TLS | HTTP only | mTLS with cert-manager |
| Observability | CloudWatch only | Prometheus + Grafana |
| Secrets | ConfigMap | AWS Secrets Manager |
| GitOps | Direct kubectl | ArgoCD / Flux |

These trade-offs are intentional and fully documented in `ARCHITECTURE.md § Design Trade-offs`.

---

Thank you for your time evaluating this submission. Please don't hesitate to reach out if you need any additional information or clarity on any design decision.

**Best regards,**  
Imtiaz Waraich  
[imtiazwaraich@example.com]  
GitHub: [@imtiazwaraich](https://github.com/imtiazwaraich)

#!/bin/bash

# Helper script to destroy all infrastructure
# Usage: ./scripts/destroy.sh

set -e

echo "⚠️  WARNING: This will destroy all Sentinel Split infrastructure!"
echo ""
read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Destruction cancelled."
    exit 0
fi

AWS_REGION="us-west-2"

echo ""
echo "Step 1: Deleting Kubernetes resources..."

# Configure kubectl
aws eks update-kubeconfig --name eks-gateway --region ${AWS_REGION} --alias eks-gateway >/dev/null 2>&1 || true
aws eks update-kubeconfig --name eks-backend --region ${AWS_REGION} --alias eks-backend >/dev/null 2>&1 || true

# Delete gateway resources
echo "  Deleting gateway resources..."
kubectl --context eks-gateway delete -f k8s/gateway/ || true

# Delete backend resources
echo "  Deleting backend resources..."
kubectl --context eks-backend delete -f k8s/backend/ || true

# Wait for LoadBalancer to be deleted
echo "  Waiting for LoadBalancer deletion..."
sleep 30

echo ""
echo "Step 2: Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve

echo ""
echo "✓ Infrastructure destroyed successfully"

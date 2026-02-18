#!/bin/bash

# Helper script to configure kubectl for both EKS clusters
# Usage: ./scripts/configure-kubectl.sh

set -e

AWS_REGION="us-west-2"

echo "Configuring kubectl for Gateway cluster..."
aws eks update-kubeconfig \
    --name eks-sentinel-v1-gateway \
    --region ${AWS_REGION} \
    --alias eks-sentinel-v1-gateway

echo "Configuring kubectl for Backend cluster..."
aws eks update-kubeconfig \
    --name eks-sentinel-v1-backend \
    --region ${AWS_REGION} \
    --alias eks-sentinel-v1-backend

echo ""
echo "✓ Successfully configured kubectl for both clusters"
echo ""
echo "Available contexts:"
kubectl config get-contexts

echo ""
echo "To switch contexts, use:"
echo "  kubectl config use-context eks-sentinel-v1-gateway"
echo "  kubectl config use-context eks-sentinel-v1-backend"

#!/bin/bash

# Helper script to configure kubectl for both EKS clusters
# Usage: ./scripts/configure-kubectl.sh

set -e

AWS_REGION="us-west-2"

echo "Configuring kubectl for Gateway cluster..."
aws eks update-kubeconfig \
    --name eks-imtiaz-gateway \
    --region ${AWS_REGION} \
    --alias eks-imtiaz-gateway

echo "Configuring kubectl for Backend cluster..."
aws eks update-kubeconfig \
    --name eks-imtiaz-backend \
    --region ${AWS_REGION} \
    --alias eks-imtiaz-backend

echo ""
echo "✓ Successfully configured kubectl for both clusters"
echo ""
echo "Available contexts:"
kubectl config get-contexts

echo ""
echo "To switch contexts, use:"
echo "  kubectl config use-context eks-imtiaz-gateway"
echo "  kubectl config use-context eks-imtiaz-backend"

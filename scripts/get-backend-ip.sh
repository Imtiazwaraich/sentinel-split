#!/bin/bash

# Helper script to get backend service internal IP for gateway configuration
# Usage: ./scripts/get-backend-ip.sh

set -e

AWS_REGION="us-west-2"

# Configure kubectl for backend cluster
aws eks update-kubeconfig --name eks-sentinel-v1-backend --region ${AWS_REGION} --alias eks-sentinel-v1-backend >/dev/null 2>&1

# Get backend service endpoint
echo "Fetching backend service information..."
echo ""

# Option 1: Pod IP (requires direct pod-to-pod communication)
POD_IP=$(kubectl --context eks-sentinel-v1-backend get pods -l app=backend -o jsonpath='{.items[0].status.podIP}')
echo "Backend Pod IP: ${POD_IP}"

# Option 2: Service ClusterIP (internal to backend cluster)
SERVICE_IP=$(kubectl --context eks-sentinel-v1-backend get svc backend-service -o jsonpath='{.spec.clusterIP}')
echo "Backend Service IP: ${SERVICE_IP}"

echo ""
echo "To configure the gateway, update k8s/gateway/configmap.yaml:"
echo "  BACKEND_SERVICE_HOST: \"${POD_IP}\""
echo "  BACKEND_SERVICE_PORT: \"80\""
echo ""
echo "Note: For production, consider using AWS Cloud Map or an internal NLB"

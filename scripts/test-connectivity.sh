#!/bin/bash

# Helper script to test connectivity from gateway to backend
# Usage: ./scripts/test-connectivity.sh

set -e

AWS_REGION="us-west-2"

echo "Testing Sentinel Split connectivity..."
echo ""

# Configure kubectl contexts
aws eks update-kubeconfig --name eks-gateway --region ${AWS_REGION} --alias eks-gateway >/dev/null 2>&1
aws eks update-kubeconfig --name eks-backend --region ${AWS_REGION} --alias eks-backend >/dev/null 2>&1

# Get backend pod IP
echo "1. Checking backend service..."
BACKEND_IP=$(kubectl --context eks-backend get pods -l app=backend -o jsonpath='{.items[0].status.podIP}')
echo "   Backend Pod IP: ${BACKEND_IP}"

# Test backend directly from backend cluster
echo ""
echo "2. Testing backend health (from backend cluster)..."
kubectl --context eks-backend exec -it deployment/backend-service -- curl -s http://localhost:8080/health
echo ""

# Get gateway LoadBalancer URL
echo "3. Checking gateway LoadBalancer..."
GATEWAY_URL=$(kubectl --context eks-gateway get svc gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "   Gateway URL: http://${GATEWAY_URL}"

# Test gateway health
echo ""
echo "4. Testing gateway health..."
curl -s http://${GATEWAY_URL}/health
echo ""

# Test end-to-end connectivity
echo "5. Testing end-to-end connectivity (gateway -> backend)..."
echo "   This should return backend response through the gateway proxy..."
curl -v http://${GATEWAY_URL}/
echo ""

echo ""
echo "✓ Connectivity test complete"

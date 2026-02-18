#!/bin/bash

# Helper script to test connectivity from gateway to backend
# Usage: ./scripts/test-connectivity.sh

set -e

AWS_REGION="us-west-2"
GATEWAY_CLUSTER="eks-sentinel-v1-gateway"
BACKEND_CLUSTER="eks-sentinel-v1-backend"

echo "Testing Sentinel Split connectivity..."
echo ""

# Configure kubectl contexts
echo "Configuring kubectl contexts..."
aws eks update-kubeconfig --name ${GATEWAY_CLUSTER} --region ${AWS_REGION} --alias ${GATEWAY_CLUSTER} >/dev/null 2>&1
aws eks update-kubeconfig --name ${BACKEND_CLUSTER} --region ${AWS_REGION} --alias ${BACKEND_CLUSTER} >/dev/null 2>&1

# Get backend pod
echo "1. Checking backend service..."
BACKEND_POD=$(kubectl --context ${BACKEND_CLUSTER} get pods -l app=backend -o jsonpath='{.items[0].metadata.name}')
BACKEND_IP=$(kubectl --context ${BACKEND_CLUSTER} get pods -l app=backend -o jsonpath='{.items[0].status.podIP}')
echo "   Backend Pod: ${BACKEND_POD} (${BACKEND_IP})"

# Test backend directly from backend cluster
echo ""
echo "2. Testing backend health (from backend cluster)..."
# Try Python fallback if curl isn't ready yet
if ! kubectl --context ${BACKEND_CLUSTER} exec ${BACKEND_POD} -- python3 -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read().decode())" 2>/dev/null; then
    echo "   Backend health check via Python failed, trying curl..."
    kubectl --context ${BACKEND_CLUSTER} exec ${BACKEND_POD} -- curl -s http://localhost:8080/health
fi
echo ""

# Get gateway LoadBalancer URL
echo "3. Checking gateway LoadBalancer..."
GATEWAY_URL=""
MAX_RETRIES=10
RETRY_COUNT=0

while [ -z "$GATEWAY_URL" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    GATEWAY_URL=$(kubectl --context ${GATEWAY_CLUSTER} get svc gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$GATEWAY_URL" ]; then
        echo "   Waiting for LoadBalancer hostname (Retry $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
        sleep 10
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ -z "$GATEWAY_URL" ]; then
    echo "Error: Failed to retrieve Gateway LoadBalancer hostname."
    exit 1
fi
echo "   Gateway URL: http://${GATEWAY_URL}"

# Test gateway health with retries
echo ""
echo "4. Testing gateway health..."
GATEWAY_HEALTHY=false
RETRY_COUNT=0
MAX_HEALTH_RETRIES=12 # 2 minutes

while [ "$GATEWAY_HEALTHY" = false ] && [ $RETRY_COUNT -lt $MAX_HEALTH_RETRIES ]; do
    if curl -s -m 5 "http://${GATEWAY_URL}/health" | grep -q "healthy"; then
        echo "   Gateway is healthy"
        GATEWAY_HEALTHY=true
    else
        echo "   Gateway not ready yet (Retry $((RETRY_COUNT + 1))/$MAX_HEALTH_RETRIES)..."
        sleep 10
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

# Test end-to-end connectivity
echo ""
echo "5. Testing end-to-end connectivity (gateway -> backend)..."
echo "   This should return backend response through the gateway proxy..."
curl -v -m 10 "http://${GATEWAY_URL}/"
echo ""

echo ""
echo "✓ Connectivity test complete"

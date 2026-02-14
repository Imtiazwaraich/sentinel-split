#!/bin/bash

set -e

AWS_REGION="us-west-2"
CLUSTER_NAME="eks-backend"

# Configure kubectl
aws eks update-kubeconfig \
  --name ${CLUSTER_NAME} \
  --region ${AWS_REGION} \
  --alias ${CLUSTER_NAME} >/dev/null 2>&1

echo "Fetching backend service information..."
echo ""

# Get Backend Pod IP
POD_IP=$(kubectl --context ${CLUSTER_NAME} \
  get pods \
  -l app=backend \
  -o jsonpath='{.items[0].status.podIP}')

echo "Backend Pod IP: ${POD_IP}"

# Get Backend Service ClusterIP
SERVICE_IP=$(kubectl --context ${CLUSTER_NAME} \
  get svc backend \
  -o jsonpath='{.spec.clusterIP}')

echo "Backend Service IP: ${SERVICE_IP}"

echo ""
echo "To configure the gateway, update k8s/gateway/configmap.yaml:"
echo "  BACKEND_SERVICE_HOST: \"${SERVICE_IP}\""
echo "  BACKEND_SERVICE_PORT: \"80\""
echo ""
echo "Note: For production, consider using AWS Cloud Map or an internal NLB"
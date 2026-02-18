# Helper script to test connectivity from gateway to backend
# Usage: .\scripts\test-connectivity.ps1

$ErrorActionPreference = "Stop"

$AWS_REGION = "us-west-2"
$GATEWAY_CLUSTER = "eks-sentinel-v1-gateway"
$BACKEND_CLUSTER = "eks-sentinel-v1-backend"

Write-Host "Testing Sentinel Split connectivity..." -ForegroundColor Cyan
Write-Host ""

# Configure kubectl contexts
Write-Host "Configuring kubectl contexts..." -ForegroundColor Yellow
& aws eks update-kubeconfig --name $GATEWAY_CLUSTER --region $AWS_REGION --alias $GATEWAY_CLUSTER | Out-Null
& aws eks update-kubeconfig --name $BACKEND_CLUSTER --region $AWS_REGION --alias $BACKEND_CLUSTER | Out-Null

# Get backend pod IP
Write-Host "1. Checking backend service..." -ForegroundColor White
$BACKEND_IP = & kubectl --context $BACKEND_CLUSTER get pods -l app=backend -o jsonpath='{.items[0].status.podIP}'
Write-Host "   Backend Pod IP: $BACKEND_IP" -ForegroundColor Green

# Test backend directly from backend cluster
Write-Host "`n2. Testing backend health (from backend cluster)..." -ForegroundColor White
& kubectl --context $BACKEND_CLUSTER exec -it deployment/backend-service -- curl -s http://localhost:8080/health
Write-Host ""

# Get gateway LoadBalancer URL
Write-Host "3. Checking gateway LoadBalancer..." -ForegroundColor White
$GATEWAY_URL = & kubectl --context $GATEWAY_CLUSTER get svc gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
Write-Host "   Gateway URL: http://$GATEWAY_URL" -ForegroundColor Green

# Test gateway health
Write-Host "`n4. Testing gateway health..." -ForegroundColor White
Invoke-RestMethod -Uri "http://$GATEWAY_URL/health" | ConvertTo-Json
Write-Host ""

# Test end-to-end connectivity
Write-Host "5. Testing end-to-end connectivity (gateway -> backend)..." -ForegroundColor White
Write-Host "   This should return backend response through the gateway proxy..." -ForegroundColor Gray
curl.exe -v "http://$GATEWAY_URL/"
Write-Host ""

Write-Host "`n✓ Connectivity test complete" -ForegroundColor Green

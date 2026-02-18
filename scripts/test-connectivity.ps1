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
$BACKEND_POD = & kubectl --context $BACKEND_CLUSTER get pods -l app=backend -o jsonpath='{.items[0].metadata.name}'
$BACKEND_IP = & kubectl --context $BACKEND_CLUSTER get pods -l app=backend -o jsonpath='{.items[0].status.podIP}'
Write-Host "   Backend Pod: $BACKEND_POD ($BACKEND_IP)" -ForegroundColor Green

# Test backend directly from backend cluster
Write-Host "`n2. Testing backend health (from backend cluster)..." -ForegroundColor White
$healthCheck = & kubectl --context $BACKEND_CLUSTER exec $BACKEND_POD -- python3 -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read().decode())" 2>$null
if ($null -eq $healthCheck) {
    Write-Host "   Backend health check failed via Python, trying curl..." -ForegroundColor Gray
    & kubectl --context $BACKEND_CLUSTER exec $BACKEND_POD -- curl -s http://localhost:8080/health
}
else {
    Write-Host "   $healthCheck" -ForegroundColor Green
}

# Get gateway LoadBalancer URL
Write-Host "`n3. Checking gateway LoadBalancer..." -ForegroundColor White
$GATEWAY_URL = ""
$maxRetries = 10
$retryCount = 0

while ([string]::IsNullOrEmpty($GATEWAY_URL) -and $retryCount -lt $maxRetries) {
    $GATEWAY_URL = & kubectl --context $GATEWAY_CLUSTER get svc gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    if ([string]::IsNullOrEmpty($GATEWAY_URL)) {
        Write-Host "   Waiting for LoadBalancer hostname (Retry $($retryCount + 1)/$maxRetries)..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $retryCount++
    }
}

if ([string]::IsNullOrEmpty($GATEWAY_URL)) {
    Write-Error "Failed to retrieve Gateway LoadBalancer hostname after $maxRetries retries."
}
Write-Host "   Gateway URL: http://$GATEWAY_URL" -ForegroundColor Green

# Test gateway health with retries
Write-Host "`n4. Testing gateway health..." -ForegroundColor White
$gatewayHealthy = $false
$retryCount = 0
$maxHealthRetries = 12 # 2 minutes total

while (-not $gatewayHealthy -and $retryCount -lt $maxHealthRetries) {
    try {
        $response = curl.exe -s -m 5 "http://$GATEWAY_URL/health"
        if ($response -like "*healthy*") {
            Write-Host "   $response" -ForegroundColor Green
            $gatewayHealthy = $true
        }
        else {
            throw "Invalid response"
        }
    }
    catch {
        Write-Host "   Gateway not ready yet (Retry $($retryCount + 1)/$maxHealthRetries)..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $retryCount++
    }
}

if (-not $gatewayHealthy) {
    Write-Warning "Gateway health check timed out. End-to-end test might fail."
}

# Test end-to-end connectivity
Write-Host "`n5. Testing end-to-end connectivity (gateway -> backend)..." -ForegroundColor White
Write-Host "   This should return backend response through the gateway proxy..." -ForegroundColor Gray
curl.exe -v -m 10 "http://$GATEWAY_URL/"
Write-Host ""

Write-Host "`n✓ Connectivity test complete" -ForegroundColor Green

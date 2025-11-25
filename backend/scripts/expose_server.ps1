
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   VISION-BASED ATTENDANCE SYSTEM - PUBLIC TUNNEL" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script exposes your local backend to the internet." -ForegroundColor Yellow
Write-Host "This allows your mobile app to connect even on restricted networks (like universities)." -ForegroundColor Yellow
Write-Host ""

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Node.js is not installed." -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor White
    exit
}

# Check if localtunnel is installed
if (-not (Get-Command lt -ErrorAction SilentlyContinue)) {
    Write-Host "Localtunnel (lt) is not installed." -ForegroundColor Yellow
    Write-Host "Installing localtunnel globally..." -ForegroundColor Cyan
    npm install -g localtunnel
}

Write-Host "Starting Tunnel for Port 5000..." -ForegroundColor Green
Write-Host "Copy the URL below (e.g., https://some-name.loca.lt) into your Mobile App Settings." -ForegroundColor White
Write-Host "IMPORTANT: After opening the URL, you might need to click 'Click to Continue' on the browser first." -ForegroundColor Red
Write-Host ""

# Start localtunnel
lt --port 5000

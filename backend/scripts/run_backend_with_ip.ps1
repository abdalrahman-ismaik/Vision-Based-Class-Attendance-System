
# Get local IP address
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*vEthernet*" }).IPAddress | Select-Object -First 1

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   VISION-BASED ATTENDANCE SYSTEM - BACKEND LAUNCHER" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your Local IP Address is: $ip" -ForegroundColor Green
Write-Host ""
Write-Host "In the Mobile App Settings, enter the following URL:" -ForegroundColor Yellow
Write-Host "http://$($ip):5000/api" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Starting Flask Server..." -ForegroundColor Gray
Write-Host ""

# Activate virtual environment if exists
if (Test-Path "..\.venv311\Scripts\Activate.ps1") {
    . ..\.venv311\Scripts\Activate.ps1
} elseif (Test-Path "..\venv\Scripts\Activate.ps1") {
    . ..\venv\Scripts\Activate.ps1
}

# Run the app
python app.py

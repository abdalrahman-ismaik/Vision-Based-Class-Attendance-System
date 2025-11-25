
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   SERVEO TUNNEL LAUNCHER (Backup Option)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This uses Serveo.net via SSH. No installation required." -ForegroundColor Yellow
Write-Host ""
Write-Host "1. If asked 'Are you sure you want to continue connecting?', type 'yes' and press Enter." -ForegroundColor White
Write-Host "2. Look for a URL like 'https://something.serveo.net' in the output." -ForegroundColor Green
Write-Host "3. Copy that URL and add '/api' for the mobile app." -ForegroundColor Green
Write-Host ""
Write-Host "Connecting to serveo.net..." -ForegroundColor Gray
Write-Host ""

# Start SSH tunnel with Serveo
# -R 80:localhost:5000 -> Forward remote port 80 to local 5000
ssh -R 80:localhost:5000 serveo.net

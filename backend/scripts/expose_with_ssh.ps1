
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "   SSH TUNNEL LAUNCHER (Robust Alternative)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This method uses SSH and does NOT require installing any tools." -ForegroundColor Yellow
Write-Host "It is often more reliable on university networks." -ForegroundColor Yellow
Write-Host ""
Write-Host "1. If asked 'Are you sure you want to continue connecting?', type 'yes' and press Enter." -ForegroundColor White
Write-Host "2. Look for a URL starting with 'https://' in the output below." -ForegroundColor Green
Write-Host "3. Copy that URL and add '/api' to the end for the mobile app." -ForegroundColor Green
Write-Host ""
Write-Host "Connecting to localhost.run..." -ForegroundColor Gray
Write-Host ""

# Start SSH tunnel
# -R 80:localhost:5000 -> Forward remote port 80 to local 5000
# nokey@localhost.run -> The service user and host
ssh -R 80:localhost:5000 nokey@localhost.run

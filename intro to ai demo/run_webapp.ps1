# Run the Vision-Based Attendance Webapp with Face Tracking
# This script starts the Flask web server for the attendance demo

Write-Host "Starting Vision-Based Attendance Webapp with Face Tracking..." -ForegroundColor Green
Write-Host ""

# Navigate to the attendance_demo directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Run the server
Write-Host "Starting server on http://127.0.0.1:5000" -ForegroundColor Cyan
Write-Host "Face tracking enabled - faces will be labeled as face1, face2, etc." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

py -m attendance_demo.server --video_source 0 --host 127.0.0.1 --port 5000

